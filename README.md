# ECS Deploy Buildkite Plugin [![Build status](https://badge.buildkite.com/02dd9bd7d4b4a6f3d80c198d7307e24bff9ae7e39ff1854bed.svg?branch=master)](https://buildkite.com/buildkite/plugins-ecs-deploy)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for deploying to [Amazon ECS](https://aws.amazon.com/ecs/).

* Requires the aws cli tool be installed
* Registers a new task definition based on a given JSON file ([`register-task-definition`](http://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html]))
* Updates the ECS service to use the new task definition ([`update-service`](http://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html))
* Waits for the service to stabilize ([`wait services-stable`](http://docs.aws.amazon.com/cli/latest/reference/ecs/wait/services-stable.html))

## Example

```yml
steps:
  - label: ":ecs: :rocket:"
    concurrency_group: "my-service-deploy"
    concurrency: 1
    plugins:
      - ecs-deploy#v1.4.1:
          cluster: "my-ecs-cluster"
          service: "my-service"
          task-definition: "examples/hello-world.json"
          task-family: "hello-world"
          image: "${ECR_REPOSITORY}/hello-world:${BUILDKITE_BUILD_NUMBER}"
```

## Options

### `cluster`

The name of the ECS cluster.

Example: `"my-cluster"`

### `service`

The name of the ECS service.

Example: `"my-service"`

### `task-definition`

The file path to the ECS task definition JSON file.

Example: `"ecs/task.json"`

### `task-family`

The name of the task family.

Example: `"my-task"`

### `image`

The Docker image to deploy. This can be an array to substitute multiple images in a single container definition.

Examples:
`"012345.dkr.ecr.us-east-1.amazonaws.com/my-service:123"`

```yaml
image:
  - "012345.dkr.ecr.us-east-1.amazonaws.com/my-service:123"
  - "012345.dkr.ecr.us-east-1.amazonaws.com/nginx:123"
```

### `task-role-arn` (optional)

An IAM ECS Task Role to assign to tasks.
Requires the `iam:PassRole` permission for the ARN specified.

### `target-group` (optional)

The Target Group ARN to map the service to.

Example: `"arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc"`

### `target-container-name` (optional)

The Container Name to forward ALB requests to.

### `target-container-port` (optional)

The Container Port to forward requests to.

### `execution-role` (optional)

The Execution Role ARN used by ECS to pull container images and secrets.

Example: `"arn:aws:iam::012345678910:role/execution-role"`

Requires the `iam:PassRole` permission for the execution role.

### `deployment-configuration` (optional)

The minimum and maximum percentage of tasks that should be maintained during a deployment. Defaults to `100/200`

Example: `"0/100"`

### `region` (optional)

The region we deploy the ECS Service to.

## AWS Roles

At a minimum this plugin requires the following AWS permissions to be granted to the agent running this step:

```yml
Policy:
  Statement:
  - Action:
    - ecr:DescribeImages
    - ecs:DescribeServices
    - ecs:RegisterTaskDefinition
    - ecs:UpdateService
    Effect: Allow
    Resource: '*'
```

This plugin will create the ECS Service if it does not already exist, which additionally requires the `ecs:CreateService` permission.

## Developing

To run the tests:

```bash
docker-compose run tests
```

## License

MIT (see [LICENSE](LICENSE))
