# ECS Deploy Buildkite Plugin ![Build status](https://badge.buildkite.com/3a4b0903b26c979f265c049c932fb4ff3c055af7a199a17216.svg)

A [Buildkite](https://buildkite.com/) plugin for deploying to Amazon's [ECS][] containers

## Example

Deploy the helloworld example:

```yml
steps:
  - plugins:
      ecs-deploy#master:
        cluster: my-ecs-cluster
        service: my-service
        task-definition: "examples/helloworld.json"
        task-family: "hello-world"
        image: ${ECR_REPOSITORY}:${BUILDKITE_BUILD_NUMBER}
```

## Configuration

Todo.


## License

MIT (see [LICENSE](LICENSE))


[ECS]: https://aws.amazon.com/ecs/
