import cfnresponse
import boto3, secrets, string, time, traceback, json
from datetime import datetime

ITEM_CATEGORY_KEY = 'category'
LAST_UPDATED_KEY = 'last-updated'
AWS_ACCOUNT_KEY = 'aws-account-id'
GENERAL_ITEM_CATEGORY = 'general'
TABLE_NAME = (
    'cloudformation-stack-emissions'
    if '${DynamoDBTableName}'.startswith('$' + '{')
    else '${DynamoDBTableName}')


def get_table_status(table_name):
    client = boto3.client('dynamodb')
    try:
        while True:
            response = client.describe_table(TableName=table_name)
            if response['Table']['TableStatus'] in ['CREATING',
                                                    'UPDATING', 'DELETING']:
                time.sleep(5)
                continue
            return response['Table']['TableStatus'] == 'ACTIVE'
    except client.exceptions.ResourceNotFoundException:
        return False


def update_table(message):
    item = dict(message['ResourceProperties'])
    # Force stacks to only be able to update items in their partition
    item[AWS_ACCOUNT_KEY] = message['StackId'].split(':')[4]
    # Case-insensitive match to "category". If ResourceProperties has
    # "Category" and "category" keys, this is non-deterministic
    item[ITEM_CATEGORY_KEY] = next(
        (iter([item[x] for x in item if x.lower() == ITEM_CATEGORY_KEY])),
        GENERAL_ITEM_CATEGORY)
    stack_path = message['StackId'].split(':')[5]
    item.setdefault('stack-name', stack_path.split('/')[1])
    item.setdefault('stack-guid', stack_path.split('/')[2])
    item.setdefault(LAST_UPDATED_KEY, datetime.utcnow().isoformat() + 'Z')

    dynamodb = boto3.resource('dynamodb')

    if message['RequestType'] == 'Delete':
        table = dynamodb.Table(TABLE_NAME)
        table.delete_item(
            Key={AWS_ACCOUNT_KEY: item[AWS_ACCOUNT_KEY],
                 ITEM_CATEGORY_KEY: item[ITEM_CATEGORY_KEY]})
        # We don't check to see if the table is now empty and can be deleted
        # because there's no cheap or easy way to determine if a table is empty
        # using either ItemCount or Scan
    elif message['RequestType'] in ['Create', 'Update']:
        while not get_table_status(TABLE_NAME):
            # TODO : Should this be moved out into the CloudFormation template?
            dynamodb.create_table(
                AttributeDefinitions=[
                    {'AttributeName': AWS_ACCOUNT_KEY, 'AttributeType': 'S'},
                    {'AttributeName': ITEM_CATEGORY_KEY,
                     'AttributeType': 'S'}],
                TableName=TABLE_NAME,
                KeySchema=[{'AttributeName': AWS_ACCOUNT_KEY,
                            'KeyType': 'HASH'},
                           {'AttributeName': ITEM_CATEGORY_KEY,
                            'KeyType': 'RANGE'}],
                ProvisionedThroughput={
                    'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1})
            time.sleep(5)
        table = dynamodb.Table(TABLE_NAME)
        table.put_item(Item=item)


def handler(event, context):
    message = always_succeed = None
    try:
        for record in event['Records']:
            message = json.loads(record['Sns']['Message'])
            always_succeed = message['RequestType'] == 'Delete'
            update_table(message)
    except Exception:
        print('Custom resource failed. Exception: {0}\n{1}'.format(
            traceback.format_exc(), event))
        status = cfnresponse.SUCCESS if always_succeed else cfnresponse.FAILED
    else:
        print('Custom resource succeeded.')
        status = cfnresponse.SUCCESS
    physical_id = ''.join(
        secrets.choice(string.ascii_uppercase + string.digits) for _ in
        range(13))
    cfnresponse.send(
        message, context, status, {},
        "ProcessCloudFormationSNSEmission-%s" % physical_id)
