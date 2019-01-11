# cloudformation-cross-account-outputs

## Deploy the infrastructure

In the AWS account that you want other accounts to emit CloudFormation outputs
to

1. Create a DynamoDB table called `cloudformation-stack-emissions`
   
   * This can be done by deploying the 
     [`cloudformation-stack-emissions-dynamodb.yml`](https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-stack-emissions-dynamodb.yml)
     CloudFormation template in the web console with this button
     [![Launch CloudFormation Stack Emission DynamoDB](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=cloudformation-stack-emissions-dynamodb&templateURL=https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-stack-emissions-dynamodb.yml),
     or by creating the table in the web console or on the command line. 
2. Deploy the CloudFormation template [`cloudformation-sns-emission-consumer-role.yml`](https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-sns-emission-consumer-role.yml)
   with this button
   [![Launch CloudFormation SNS Emission Consumer Role](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=cloudformation-sns-emission-consumer-role&templateURL=https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-sns-emission-consumer-role.yml)
   in a single region which will create an IAM Role used by the Lambda function
3. Deploy the CloudFormation template [`cloudformation-sns-emission-consumer.yml`](https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-sns-emission-consumer.yml)
   with these buttons in every region that you need to receive CloudFormation 
   outputs in. (You're welcome to deploy the template in regions other than 
   those listed below)
   
   * `us-west-2` : [![Launch CloudFormation SNS Emission Consumer](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=cloudformation-sns-emission-consumer&templateURL=https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-sns-emission-consumer.yml)
   * `us-east-1` : [![Launch CloudFormation SNS Emission Consumer](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=cloudformation-sns-emission-consumer&templateURL=https://s3-us-west-2.amazonaws.com/public.us-west-2.infosec.mozilla.org/cloudformation-cross-account-outputs/cf/cloudformation-sns-emission-consumer.yml)
   
   Since CloudFormation custom resources can only emit to SNS topics in the same
   region, a separate SNS topic must be deployed in every region that you use.
   This stack creates
   
   * An SNS Topic to which other accounts will emit events to and Topic Policy
   * A Lambda function subscribed to that SNS Topic

## Emit outputs from a CloudFormation template

Create a CloudFormation template containing
* A [CloudFormation Custom Resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cfn-customresource.html)
  with the following properties
  * `ServiceToken` : The SNS ARN of the SNS topic you created when deploying the
    infrastructure
  * An arbitrary number of additional key value pairs. In the example below
    there's a single key value pair with a key of `exampleKey` and value of
    `Example Value`

Note : You may want to constrain users from deploying this template in regions
where you've not deployed an [SNS topic](cloudformation/cloudformation-sns-emission-consumer-topic.yml)
to receive stack emissions. One way to do this is [with a region Mapping](https://gist.github.com/gene1wood/ae2b77a424d220f2d0605cb8637baa33)

### Example CloudFormation template

```yaml
AWSTemplateFormatVersion: 2010-09-09
Resources:
  PublishTestToSNS:
    Type: Custom::PublishIAMRoleArnsToSNS
    Version: '1.0'
    Properties:
      ServiceToken: !Join [ ':', [ 'arn:aws:sns', !Ref 'AWS::Region', '012345678901', 'cloudformation-stack-emissions' ] ]
      exampleKey: Example Value
```

## Fetch emitted outputs

You can fetch data from the DynamoDB table with the aws command line. To fetch
the `exampleKey` value for all emissions in account `012345678901` query like
this

```
aws dynamodb query --table-name cloudformation-stack-emissions \
  --expression-attribute-names '{"#a": "aws-account-id"}' \
  --expression-attribute-values '{":i": {"S": "012345678901"}}' \
  --key-condition-expression "#a = :i" \
  --projection-expression exampleKey \
  --output text --query 'Items[].exampleKey.S'
```

### Automatically added attributes

The following attributes are always set
* `aws-account-id` : The AWS account ID in which the CloudFormation stack was
  deployed
* `stack-id` : The GUID of the CloudFormation stack

The following attributes are set if they aren't passed in the `Properties` of
the CloudFormation stack
* `region` : The AWS region in which the CouldFormation stack was deployed
* `stack-name` : The name of the CloudFormation stack
* `last-updated` : The datetime that the record was last updated in UTC time

## DynamoDB Schema

* Table name : `cloudformation-stack-emissions`
* Partition key : `aws-account-id` which contains the [AWS Account ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)
  of the AWS account that contains the CloudFormation stack which is emitting
  data
* Sort key : `stack-id` which contains the CloudFormation stack's GUID.
* Attributes : All additional Resource Properties of the CloudFormation Custom
  Resource are inserted into a DynamoDB Item as attributes (key value pairs)
  
