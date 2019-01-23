ROOT_DIR	:= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PARENTDIR       := $(realpath ../)
AWS_DEFAULT_REGION = us-west-2
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
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws s3 sync cloudformation/ $(S3_BUCKET_TEMPLATE_URI) --exclude="*" --include="*.yml"

.PHONY: create-stacks
create-stacks: create-consumer-stacks create-role-stack create-dynamodb-stack

.PHONY: create-consumer-stacks
create-consumer-stacks:
	AWS_DEFAULT_REGION=us-west-2 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-us-west-2 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=us-east-1 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-us-east-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=us-west-1 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-us-west-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=eu-west-1 aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-eu-west-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml

.PHONY: create-role-stack
create-role-stack:
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws cloudformation create-stack --stack-name cloudformation-sns-emission-consumer-role \
	  --capabilities CAPABILITY_IAM \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer-role.yml

.PHONY: create-dynamodb-stack
create-dynamodb-stack:
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws cloudformation create-stack --stack-name cloudformation-stack-emissions-dynamodb \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-stack-emissions-dynamodb.yml

.PHONY: create-test-stack
create-test-stack:
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws cloudformation create-stack --stack-name test-stack-emission \
	  --template-body file://tests/test_emission.yml

.PHONY: update-stacks
update-stacks: update-consumer-stacks update-role-stack update-dynamodb-stack

.PHONY: update-consumer-stacks
update-consumer-stacks:
	AWS_DEFAULT_REGION=us-west-2 aws cloudformation update-stack --stack-name cloudformation-sns-emission-consumer-us-west-2 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=us-east-1 aws cloudformation update-stack --stack-name cloudformation-sns-emission-consumer-us-east-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=us-west-1 aws cloudformation update-stack --stack-name cloudformation-sns-emission-consumer-us-west-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml
	AWS_DEFAULT_REGION=eu-west-1 aws cloudformation update-stack --stack-name cloudformation-sns-emission-consumer-eu-west-1 \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer.yml

.PHONY: update-role-stack
update-role-stack:
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws cloudformation update-stack --stack-name cloudformation-sns-emission-consumer-role \
	  --capabilities CAPABILITY_IAM \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-sns-emission-consumer-role.yml

.PHONY: update-dynamodb-stack
update-dynamodb-stack:
	AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws cloudformation update-stack --stack-name cloudformation-stack-emissions-dynamodb \
	  --template-url $(HTTP_BUCKET_TEMPLATE_URI)/cloudformation-stack-emissions-dynamodb.yml
