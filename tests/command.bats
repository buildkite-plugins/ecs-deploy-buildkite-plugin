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
    "--arg IMAGE hello-world:llamas '.[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1" \
    "-r .loadBalancers[0] : echo null"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query services[0].{loadBalancers:loadBalancers} : echo 'null'" \
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
  unset BUILDKITE_PLUGIN_ECS_DEPLOY_IMAGE
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
    "--arg IMAGE hello-world:llamas '.[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1" \
    "-r .loadBalancers[0] : echo null"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query services[0].{loadBalancers:loadBalancers} : echo 'null'" \
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

  stub jq \
    "--arg IMAGE hello-world:llamas '.[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1" \
    "-r .loadBalancers[0] : echo null"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' --task-role-arn arn:aws:iam::012345678910:role/world : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo '1'" \
    "ecs describe-services --cluster my-cluster --services my-service --query services[0].{loadBalancers:loadBalancers} : echo 'null'" \
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

  stub jq \
    "--arg IMAGE hello-world:llamas '.[0].image=\$IMAGE' examples/hello-world.json : echo '{\"json\":true}'" \
    "'.taskDefinition.revision' : echo 1" \
    "-r .loadBalancers[0] : echo alb" \
    "-r .containerName : echo nginx" \
    "-r .containerPort : echo 80"

  stub aws \
    "ecs register-task-definition --family hello-world --container-definitions '{\"json\":true}' : echo '{\"taskDefinition\":{\"revision\":1}}'" \
    "ecs describe-services --cluster my-cluster --service my-service --query 'services[*].status' --output text : echo -n ''" \
    "ecs create-service --cluster my-cluster --service-name my-service --task-definition hello-world:1 --desired-count 1 --load-balancers \'targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:012345678910:targetgroup/alb/e987e1234cd12abc,containerName=nginx,containerPort=80\' : echo -n ''" \
    "ecs describe-services --cluster my-cluster --services my-service --query services[0].{loadBalancers:loadBalancers} : echo '[{\"loadBalancerName\": \"alb\",\"containerName\": \"nginx\",\"containerPort\": 80}]'" \
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
