# cloudformation-cross-account-outputs

## DynamoDB Schema

* Table name : `cloudformation-stack-emissions`
* Partition key : `aws-account-id` which contains the [AWS Account ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)
  of the AWS account that contains the CloudFormation stack which is emitting
  data
* Sort key : Defined by each stack with a [Resource Property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html)
  called `category`. If a `category` Resouce Property isn't included the the
  CloudFormation Custom Resource, `category` is set to a value of `general`
* Attributes : All additional Resource Properties of the CloudFormation Custom
  Resource are inserted into a DynamoDB Item as attributes (key value pairs)
  
