import cfnresponse
import boto3, secrets, string, time, traceback, json
from datetime import datetime

LAST_UPDATED_KEY = 'last-updated'
ACCOUNT_ID_KEY = 'aws-account-id'
STACK_ID_KEY = 'stack-id'
LOGICAL_RESOURCE_ID_KEY = 'logical-resource-id'
TABLE_NAME = (
    'cloudformation-stack-emissions'
    if '${DynamoDBTableName}'.startswith('$' + '{')
    else '${DynamoDBTableName}')
TABLE_REGION = (
    'us-west-2'
    if '${DynamoDBTableRegion}'.startswith('$' + '{')
    else '${DynamoDBTableRegion}')


def get_table_status(table_name):
    client = boto3.client('dynamodb', region_name=TABLE_REGION)
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
    del(item['ServiceToken'])
    stack_path = message['StackId'].split(':')[5]
    stack_guid = stack_path.split('/')[2]

    # Force resources in stacks to only be able to update items that they
    # created
    item[STACK_ID_KEY] = stack_guid
    item[LOGICAL_RESOURCE_ID_KEY] = message['LogicalResourceId']

    item[ACCOUNT_ID_KEY] = message['StackId'].split(':')[4]
    item.setdefault('stack-name', stack_path.split('/')[1])
    item.setdefault('region', message['StackId'].split(':')[3])
    item.setdefault(LAST_UPDATED_KEY, datetime.utcnow().isoformat() + 'Z')

    dynamodb = boto3.resource('dynamodb', region_name=TABLE_REGION)

    if message['RequestType'] == 'Delete':
        table = dynamodb.Table(TABLE_NAME)
        table.delete_item(
            Key={STACK_ID_KEY: item[STACK_ID_KEY],
                 LOGICAL_RESOURCE_ID_KEY: item[LOGICAL_RESOURCE_ID_KEY]})
        # We don't check to see if the table is now empty and can be deleted
        # because there's no cheap or easy way to determine if a table is empty
        # using either ItemCount or Scan
    elif message['RequestType'] in ['Create', 'Update']:
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
    if 'PhysicalResourceId' in message:
        physical_id = message['PhysicalResourceId']
    else:
        random_string = ''.join(
            secrets.choice(string.ascii_uppercase + string.digits)
            for _ in range(13))
        physical_id = "ProcessCloudFormationSNSEmission-{}".format(
            random_string)
    cfnresponse.send(message, context, status, {}, physical_id)
