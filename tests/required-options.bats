#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# Uncomment to enable stub debug output:
# export AWS_STUB_DEBUG=/dev/tty

@test "Fail with missing cluster" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing cluster"
}

@test "Fail with missing service" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/hello-world.json

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing service name"
}

@test "Fail with missing task family" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/hello-world.json

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing task family"
}

@test "Fail with missing deploy image" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/hello-world.json

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing image to use"
}