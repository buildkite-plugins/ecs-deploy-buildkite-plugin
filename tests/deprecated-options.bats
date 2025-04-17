#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# Uncomment to enable stub debug output:
# export AWS_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
}

@test "Fail with task-definition" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/task-definition.json

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "The task-definition parameter has been deprecated"
}

@test "Fail with service definition" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE_DEFINITION=examples/service-definition.json

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "service-definition parameter has been deprecated"
}

@test "Warn with other options" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOYMENT_CONFIG='100/200'
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOYMENT_CONFIGURATION='100/200'
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DESIRED_COUNT='2'
  export BUILDKITE_PLUGIN_ECS_DEPLOY_LOAD_BALANCER_NAME='test-elb'
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_NAME='mycontainer'
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_PORT=8000
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_GROUP='mygroup'

  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions \* : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[].events[]' : echo '[]'"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "deployment-config parameter has been deprecated"
  assert_output --partial "deployment-configuration parameter has been deprecated"
  assert_output --partial "load-balancer-name parameter has been deprecated"
  assert_output --partial "target-container-name parameter has been deprecated"
  assert_output --partial "target-container-port parameter has been deprecated"
  assert_output --partial "target-group parameter has been deprecated"

  unstub aws
}