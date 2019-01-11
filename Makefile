ROOT_DIR	:= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PARENTDIR       := $(realpath ../)
AWS_REGION = us-west-2
S3_BUCKET_NAME  := public.us-west-2.infosec.mozilla.org
S3_BUCKET_TEMPLATE_PATH	:= cloudformation-cross-account-outputs/cf
S3_BUCKET_TEMPLATE_URI	:= s3://$(S3_BUCKET_NAME)/$(S3_BUCKET_TEMPLATE_PATH)
HTTP_BUCKET_TEMPLATE_URI	:= https://s3.amazonaws.com/$(S3_BUCKET_NAME)/$(S3_BUCKET_TEMPLATE_PATH)

all:
	@echo 'Available make targets:'
	@grep '^[^#[:space:]].*:' Makefile

.PHONY: cfn-lint test
test: cfn-lint
cfn-lint: ## Verify the CloudFormation templates pass linting tests
	-cfn-lint cloudformation/*.yml

.PHONY: upload-templates
upload-templates:
	AWS_REGION=$(AWS_REGION) aws s3 sync cloudformation/ $(S3_BUCKET_TEMPLATE_URI) --exclude="*" --include="*.yml"

.PHONY: create-stacks
create-stacks:
	AWS_REGION=us-west-2 aws cloudformation create-stack --stack-name cloudformation-stack-emissions-dynamodb \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-stack-emissions-dynamodb.yml
	AWS_REGION=us-west-2 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-role \
	  --capabilities CAPABILITY_IAM \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer-role.yml
	AWS_REGION=us-west-2 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-us-west-2 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_REGION=us-east-1 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-us-east-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
