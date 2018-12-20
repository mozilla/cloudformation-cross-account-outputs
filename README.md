# cloudformation-cross-account-outputs

## Usage

### Deploy the infrastructure

In the AWS account that you want other accounts to emit CloudFormation outputs
to
1. Create a DynamoDB table called `cloudformation-stack-emissions`
   * This can be done by deploying the [`cloudformation-stack-emissions-dynamodb.yml`](cloudformation-stack-emissions-dynamodb.yml)
     CloudFormation template, creating the table in the web console or on the command line
2. Deploy the CloudFormation template [`cloudformation-sns-emission-consumer.yml`](cloudformation-sns-emission-consumer.yml)
   which will create
   * An SNS Topic and Topic Policy to which other accounts will emit events to
   * A Lambda function that will subscribe to that SNS Topic and an IAM Role that
     the Lambda function will run as

### Emit outputs from a CloudFormation template

Create a CloudFormation template containing
* A [CloudFormation Custom Resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cfn-customresource.html)
  with the following properties
  * `ServiceToken` : The SNS ARN of the SNS topic you created when deploying the
    infrastructure
  * `category` : This optional property will set the `category` value of the item
    stored in the DynamoDB table. This will be the [sort key](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html#HowItWorks.CoreComponents.PrimaryKey)
    which combined with the AWS account ID stored in the `aws-account-id` attribute
    in the table make up the composite primary key. If `category` is not set in
     the CloudFormation custom resource, a value of `general` will be used
  * An arbitrary number of additional key value pairs. In the example below
    there's a single key value pair with a key of `exampleKey` and value of
    `Example Value`

#### Example CloudFormation template

```yaml
AWSTemplateFormatVersion: 2010-09-09
Parameters:
  SNSArnForPublishingTo:
    Type: String
    Default: arn:aws:sns:us-west-2:656532927350:cloudformation-stack-emissions
    Description: The ARN of the SNS Topic to publish an event to
Resources:
  PublishTestToSNS:
    Type: Custom::PublishIAMRoleArnsToSNS
    Version: '1.0'
    Properties:
      ServiceToken: !Ref SNSArnForPublishingTo
      category: testing
      exampleKey: Example Value
```

### Fetch emitted outputs

You can fetch data from the DynamoDB table with the aws command line. To fetch
the `exampleKey` value for all emissions in account `012345678901` query like
this

```
aws dynamodb query --table-name cloudformation-stack-emissions \
  --expression-attribute-names '{"#a": "aws-account-id"}' \
  --expression-attribute-values '{":i": {"S": "012345678901"}}' \
  --key-condition-expression "#a = :i"` \
  --projection-expression exampleKey \
  --output text --query 'Items[].exampleKey.S'
```

#### DynamoDB Schema

* Table name : `cloudformation-stack-emissions`
* Partition key : `aws-account-id` which contains the [AWS Account ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)
  of the AWS account that contains the CloudFormation stack which is emitting
  data
* Sort key : Defined by each stack with a [Resource Property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html)
  called `category`.
* Attributes : All additional Resource Properties of the CloudFormation Custom
  Resource are inserted into a DynamoDB Item as attributes (key value pairs)
  
