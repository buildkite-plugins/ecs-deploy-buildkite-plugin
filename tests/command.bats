#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment to enable stub debug output:
# export AWS_STUB_DEBUG=/dev/tty
# export JQ_STUB_DEBUG=/dev/tty

@test "Run a deploy when service exists" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json

  stub jq \
    "--arg IMAGE hello-world:llamas '.taskDefinition.containerDefinitions[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo '1'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unstub jq
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
}

@test "Run a deploy when service does not exist" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json

  stub jq \
    "--arg IMAGE hello-world:llamas '.taskDefinition.containerDefinitions[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 : echo -n ''" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unstub jq
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
}
