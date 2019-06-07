# ECS Deploy Buildkite Plugin ![Build status](https://badge.buildkite.com/67da940833c8744761259918c52d4a005e2b5599a173d1e131.svg?branch=master)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for deploying to [Amazon ECS](https://aws.amazon.com/ecs/).

* Requires the aws cli tool be installed
* Registers a new task definition based on a given JSON file ([`register-task-definition`](http://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html]))
* Updates the ECS service to use the new task definition ([`update-service`](http://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html))
* Waits for the service to stabilize ([`wait services-stable`](http://docs.aws.amazon.com/cli/latest/reference/ecs/wait/services-stable.html))

_The ECS service must have been created before using this plugin._

## Example

```yml
steps:
  - label: ":ecs: :rocket:"
    concurrency_group: "my-service-deploy"
    concurrency: 1
    plugins:
      - ecs-deploy#v1.2.0:
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

### `target-group`

The Target Group ARN to map the service to.

Example: `"arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc"`

### `target-container-name`

The Container Name to forward ALB requests to.

### `target-container-port`

The Container Port to forward requests to.

## AWS Roles

Requires the following AWS roles to be granted to the agent running this step:

* TODO

## Developing

To run the tests:

```bash
docker-compose run tests
```

## License

MIT (see [LICENSE](LICENSE))
