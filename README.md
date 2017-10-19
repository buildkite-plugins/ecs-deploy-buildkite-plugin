# ECS Deploy Buildkite Plugin ![Build status](https://badge.buildkite.com/67da940833c8744761259918c52d4a005e2b5599a173d1e131.svg)

A [Buildkite](https://buildkite.com/) plugin for deploying to [Amazon ECS](https://aws.amazon.com/ecs/).

* Requires the aws cli tool be installed
* Registers a new task definition based on a given JSON file
* Updates the ECS service to use the new task definition
* Waits for the 

_The ECS service must have been created before using this plugin._

## Example

```yml
steps:
  - label: ":ecs: :rocket:"
    concurrency_group: "my-service-deploy"
    concurrency: 1
    plugins:
      ecs-deploy#master:
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

The Docker image to deploy.

Example: `"012345.dkr.ecr.us-east-1.amazonaws.com/my-service:123"`

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
