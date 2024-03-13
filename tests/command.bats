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

@test "Run a deploy when service exists" {

  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions \* : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[].events' --output text : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
}

@test "Run a deploy with multiple images" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/multiple-images.json
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE # we are providing an array
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1=hello-world:alpacas

  expected_multiple_container_definition='[\n  {\n    "essential": true,\n    "image": "hello-world:llamas",\n    "memory": 100,\n    "name": "sample",\n    "portMappings": [\n      {\n        "containerPort": 80,\n        "hostPort": 80\n      }\n    ]\n  },\n  {\n    "essential": true,\n    "image": "hello-world:alpacas",\n    "memory": 100,\n    "name": "sample",\n    "portMappings": [\n      {\n        "containerPort": 80,\n        "hostPort": 80\n      }\n    ]\n  }\n]'

  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_multiple_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[].events' --output text : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
}

@test "Add env vars on multiple images" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CONTAINER_DEFINITIONS=examples/multiple-images.json
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE # we are providing an array
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1=hello-world:alpacas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_0="FOO=bar"
  export BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_1="BAZ=bing"


  # first command stubbed saves the container definition to ${TMP_DIR}/container_definition for later review and manipulation
  # we should be stubbing a lot more calls, but we don't care about those so let the stubbing fail
  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions \* : echo \"\$6\" > ${_TMP_DIR}/container_definition ; echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[].events' --output text : echo ok"

  run "$PWD/hooks/command"

  assert_success

  # check that the definition was updated accordingly
  assert_equal "$(jq -r '.[0].environment[0].name'  "${_TMP_DIR}"/container_definition)" 'FOO'
  assert_equal "$(jq -r '.[0].environment[0].value' "${_TMP_DIR}"/container_definition)" 'bar'
  assert_equal "$(jq -r '.[1].environment[0].name'  "${_TMP_DIR}"/container_definition)" 'FOO'
  assert_equal "$(jq -r '.[1].environment[0].value' "${_TMP_DIR}"/container_definition)" 'bar'
  assert_equal "$(jq -r '.[0].environment[1].name'  "${_TMP_DIR}"/container_definition)" 'BAZ'
  assert_equal "$(jq -r '.[0].environment[1].value' "${_TMP_DIR}"/container_definition)" 'bing'
  assert_equal "$(jq -r '.[1].environment[1].name'  "${_TMP_DIR}"/container_definition)" 'BAZ'
  assert_equal "$(jq -r '.[1].environment[1].value' "${_TMP_DIR}"/container_definition)" 'bing'

  unstub aws
}

@test "Run a deploy with task role" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_ROLE_ARN=arn:aws:iam::012345678910:role/world

  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions \* --task-role-arn arn:aws:iam::012345678910:role/world : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[].events' --output text : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
}

@test "Run a deploy with execution role" {
  export BUILDKITE_PLUGIN_ECS_DEPLOY_EXECUTION_ROLE=arn:aws:iam::012345678910:role/world

  stub aws \
    "ecs describe-task-definition --task-definition hello-world --query 'taskDefinition' : echo '{}'" \
    "ecs register-task-definition --family hello-world --container-definitions \* --execution-role-arn arn:aws:iam::012345678910:role/world : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[].events' --output text : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
}