#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

setup() {
  # emulate the upcoming bats `setup_file`
  # https://github.com/bats-core/bats-core/issues/39#issuecomment-377015447
  if [[ $BATS_TEST_NUMBER -eq 1 ]]; then
    # output to fd 3, prefixed with hashes, for TAP compliance:
    # https://github.com/bats-core/bats-core/blob/v1.2.0/README.md#printing-to-the-terminal
    apk --no-cache add jq | sed -e 's/^/# /' >&3
  fi
}

# Uncomment to enable stub debug output:
# export AWS_STUB_DEBUG=/dev/tty

expected_container_definition='[\n  {\n    "essential": true,\n    "image": "hello-world:llamas",\n    "memory": 100,\n    "name": "sample",\n    "portMappings": [\n      {\n        "containerPort": 80,\n        "hostPort": 80\n      }\n    ]\n  }\n]'

@test "Run a deploy when service exists" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'${expected_container_definition}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
}

@test "Run a deploy with multiple images" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1=hello-world:alpacas

  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/multiple-images.json

  expected_container_definition='[\n  {\n    "essential": true,\n    "image": "hello-world:llamas",\n    "memory": 100,\n    "name": "sample",\n    "portMappings": [\n      {\n        "containerPort": 80,\n        "hostPort": 80\n      }\n    ]\n  },\n  {\n    "essential": true,\n    "image": "hello-world:alpacas",\n    "memory": 100,\n    "name": "sample",\n    "portMappings": [\n      {\n        "containerPort": 80,\n        "hostPort": 80\n      }\n    ]\n  }\n]'

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1
}

@test "Add env vars on multiple images" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1=hello-world:alpacas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_0="FOO=bar"
  export BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_1="BAZ=bing"

  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/multiple-images.json

  # first command stubbed saves the container definition to ${_TMP_DIR}/container_definition for later review and manipulation
  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '*' : echo \"\$6\" > ${_TMP_DIR}/container_definition ; echo '{\"taskDefinition\":{\"revision\":1}}'"

  run "$PWD/hooks/command"

  # there is no assert_success because we are just checking that the definition was updated accordingly
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[0].environment[0].name') 'FOO'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[0].environment[0].value') 'bar'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[1].environment[0].name') 'FOO'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[1].environment[0].value') 'bar'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[0].environment[1].name') 'BAZ'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[0].environment[1].value') 'bing'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[1].environment[1].name') 'BAZ'
  assert_equal $(cat ${_TMP_DIR}/container_definition | jq -r '.[1].environment[1].value') 'bing'

  # as the aws command is called more times than stubbed, it is unstubbed automatically
  # unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_0
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE_1
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_0
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_ENV_1
}

@test "Run a deploy when service does not exist" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 --deployment-configuration maximumPercent=200,minimumHealthyPercent=100 : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
}

@test "Run a deploy with task role" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_ROLE_ARN=arn:aws:iam::012345678910:role/world

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' --task-role-arn arn:aws:iam::012345678910:role/world : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_ROLE_ARN
}

@test "Run a deploy with target group" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_GROUP=arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_NAME=nginx
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_PORT=80

  alb_config='[{"loadBalancers":[{"containerName":"nginx","containerPort":80,"targetGroupArn":"arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc"}]}]'

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 --deployment-configuration maximumPercent=200,minimumHealthyPercent=100 --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc,containerName=nginx,containerPort=80 : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo '$alb_config'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_GROUP
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_NAME
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_PORT
}

@test "Run a deploy with ELBv1" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_LOAD_BALANCER_NAME=nginx-elb
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_NAME=nginx
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_PORT=80

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 --deployment-configuration maximumPercent=200,minimumHealthyPercent=100 --load-balancers loadBalancerName=nginx-elb,containerName=nginx,containerPort=80 : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo '[{\"loadBalancers\":[{\"loadBalancerName\": \"nginx-elb\",\"containerName\": \"nginx\",\"containerPort\": 80}]}]'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_NAME
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TARGET_CONTAINER_PORT
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_LOAD_BALANCER_NAME
}

@test "Run a deploy with execution role" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_EXECUTION_ROLE=arn:aws:iam::012345678910:role/world

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' --execution-role-arn arn:aws:iam::012345678910:role/world : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_EXECUTION_ROLE
}

@test "Create a service with deployment configuration" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=examples/hello-world.json
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOYMENT_CONFIGURATION="0/100"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions $'$expected_container_definition' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[?status==\`ACTIVE\`].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 --deployment-configuration maximumPercent=100,minimumHealthyPercent=0 : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query 'services[?status==\`ACTIVE\`]' : echo 'null'" \
    "ecs update-service --cluster my-cluster --service my-service --task-definition hello-world:1 : echo ok" \
    "ecs wait services-stable --cluster my-cluster --services my-service : echo ok" \
    "ecs describe-services --cluster my-cluster --service my-service : echo ok"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Service is up 🚀"

  unstub aws
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOYMENT_CONFIGURATION
}

@test "Run a deploy when the container definition is incorrect" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER=my-cluster
  export BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE=my-service
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_FAMILY=hello-world
  export BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE=hello-world:llamas
  export BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION=tests/incorrect-container-definition.json

  run "$PWD/hooks/command"
  assert_failure
  assert_output --partial 'JSON definition should be in the format of [{"image": "..."}]'

  unset BUILDKITE_PLUGIN_ECS_DEPLOY_CLUSTER
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_SERVICE
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_TASK_DEFINITION
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
  unset BUILDKITE_BUILD_NUMBER
}
