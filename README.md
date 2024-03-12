# ECS Deploy Buildkite Plugin [![Build status](https://badge.buildkite.com/02dd9bd7d4b4a6f3d80c198d7307e24bff9ae7e39ff1854bed.svg?branch=master)](https://buildkite.com/buildkite/plugins-ecs-deploy)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for deploying to [Amazon ECS](https://aws.amazon.com/ecs/).

* Requires both `aws` and `jq` cli tools to be installed
* Registers a new task definition based on a given JSON file ([`register-task-definition`](http://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html))
* Updates the ECS service to use the new task definition ([`update-service`](http://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html))
* Waits for the service to stabilize ([`wait services-stable`](http://docs.aws.amazon.com/cli/latest/reference/ecs/wait/services-stable.html))

## Example

```yml
steps:
  - label: ":ecs: :rocket:"
    concurrency_group: "my-service-deploy"
    concurrency: 1
    plugins:
      - ecs-deploy#v2.1.0:
          cluster: "my-ecs-cluster"
          service: "my-service"
          container-definitions: "examples/hello-world.json"
          task-family: "hello-world"
          image: "${ECR_REPOSITORY}/hello-world:${BUILDKITE_BUILD_NUMBER}"
```

## Options

### Required

#### `cluster`

The name of the ECS cluster.

Example: `"my-cluster"`

#### `container-definitions`

_Experimental:_ Since version 3.0.0 you can skip this parameter and the container definitions will be obtained off the existing (latest) task definition. If this does not work for you, please open an issue in this repository.

The file path to the ECS container definition JSON file. This JSON file must be an array of objects, each corresponding to one of the images you defined in the `image` parameter.

Example: `"ecs/containers.json"`
```json
[
    {
        "essential": true,
        "image": "amazon/amazon-ecs-sample",
        "memory": 100,
        "name": "sample",
        "portMappings": [
            {
                "containerPort": 80,
                "hostPort": 80
            }
        ]
    },
    {
        "essential": true,
        "image": "amazon/amazon-ecs-sample",
        "memory": 100,
        "name": "sample",
        "portMappings": [
            {
                "containerPort": 80,
                "hostPort": 80
            }
        ]
    }
]
```

#### `image`

The Docker image to deploy. This can be an array to substitute multiple images in a single container definition.

Examples:
`"012345.dkr.ecr.us-east-1.amazonaws.com/my-service:123"`

```yaml
image:
  - "012345.dkr.ecr.us-east-1.amazonaws.com/my-service:123"
  - "012345.dkr.ecr.us-east-1.amazonaws.com/nginx:123"
```

#### `service`

The name of the ECS service.

Example: `"my-service"`

#### `task-family`

The name of the task family.

Example: `"my-task"`

### Optional

#### `env` (array)

An array of environment variables to add to *every* image's task definition in the `NAME=VALUE` format

#### `execution-role`

The Execution Role ARN used by ECS to pull container images and secrets.

Example: `"arn:aws:iam::012345678910:role/execution-role"`

Requires the `iam:PassRole` permission for the execution role.

#### `region`

The region we deploy the ECS Service to.

#### `task-cpu` (integer)

CPU Units to assign to the task (1024 constitutes a whole CPU). Example: `256` (1/4 of a CPU).

#### `task-ephemeral-storage` (integer)

Amount of GBs to assign in ephemeral storage to the task. Example: `25`.

#### `task-ipc-mode`

IPC resource namespace to use in the task. If specified, should be one of `host`, `task` or `none`.

#### `task-memory` (integer)

Amount of memory (in Mbs) to allocate for the task. Example: `1024` (1Gb).

#### `task-network-mode`

Docker networking mode for the containers running in the task. If specified, should be one of `bridge`, `host`, `awsvpc` or `none`.

#### `task-pid-mode`

Process namespace to use for containers in the task. If specified, should be one of `host` or `task`.

#### `task-role-arn`

An IAM ECS Task Role to assign to tasks.

Requires the `iam:PassRole` permission for the ARN specified.

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

## Developing

To run testing, shellchecks and plugin linting use use `bk run` with the [Buildkite CLI](https://github.com/buildkite/cli).

```bash
bk run
```

Or if you want to run just the tests, you can use the docker [Plugin Tester](https://github.com/buildkite-plugins/buildkite-plugin-tester):

```bash
docker run --rm -ti -v "${PWD}":/plugin buildkite/plugin-tester:latest
```

## License

MIT (see [LICENSE](LICENSE))
