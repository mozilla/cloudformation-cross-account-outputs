# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.1.0] - 2022-12-12

### Changed

- AWS Lambda function to use supported Python 3.9 runtime
- Parameterize all hard coded CloudFormation template values and add a stack
  output of `DynamoDBTableName` thanks to [@NitriKx](https://github.com/NitriKx)
  in [#15](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/15).

### Fixed

- Corrupted Lambda introduced in [#15](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/15)

## [4.0.0] - 2019-01-30

### Changed

- The DynamoDB table schema, modifying the partition key and sort key and 
  establishing an additional Global Secondary Index. These changes facilitate
  querying for either the items in a given AWS account or the items with a given 
  category value. [#11](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/11)

## [3.0.0] - 2019-01-23

### Added

- Support for a stack to have multiple resources that emit data and for a single
  stack to produce multiple records in DynamoDB. [#9](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/9)
- New Makefile targets for more granular control when deploying CloudFormation
  stacks. [#9](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/9)

### Changed

- The DynamoDB table schema, changing the partition key from account ID to stack
  ID and the sort key from stack ID to logical resource ID so that each resource
  within a given CloudFormation stack has unique rights to edit/delete the 
  attributes it sets. [#9](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/9)

## [2.0.0] - 2019-01-11

### Added

- A Makefile. [#8](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/8)
- Support for more than one region [#6](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/6)
- Documentation [#4](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/4)

### Changed

- The DynamoDB schema to prevent multiple stacks in the same account from 
  overwriting each other. Originally this was intentional in the design but 
  after working through trying to use it, it became apparent that it wasn't 
  ideal. [#6](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/6)

### Fixed

- PhysicalResourceId so that the Lambda function checks for the presense of a 
  PhysicalResourceId in the message and uses that if it's present instead of 
  generating one.  [#7](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/7)

## [1.0.0] - 2018-12-20

## Added

- Last updated field in output records [#4](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/4)
- The initial commit. [#2](https://github.com/mozilla/cloudformation-cross-account-outputs/pull/2)


[Unreleased]: https://github.com/mozilla/cloudformation-cross-account-outputs/compare/v4.1.0...HEAD
[4.1.0]: https://github.com/mozilla/cloudformation-cross-account-outputs/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/mozilla/cloudformation-cross-account-outputs/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/mozilla/cloudformation-cross-account-outputs/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/mozilla/cloudformation-cross-account-outputs/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/mozilla/cloudformation-cross-account-outputs/releases/tag/v1.0.0
