#!/usr/bin/env bats

apk --no-cache add jq

load '/usr/local/lib/bats/load.bash'

# Uncomment to enable stub debug output:
# export AWS_STUB_DEBUG=/dev/tty

@test "Fail when multiple config paths are given" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOY="path/to/config1.json"
  export BUILDKITE_PLUGIN_ECS_DEPLOY_VALIDATE="path/to/config1.json"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "One of either validate or deploy must be specified"

  unset BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOY
}

@test "Fail when no config paths are given" {
  export BUILDKITE_BUILD_NUMBER=1

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "One of either validate or deploy must be specified"
}

# The below two tests assert failure as the error thrown from the docker command
# is the simplest way of distinguising which function has been called

@test "A deploy config is passed to the deploy command" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_DEPLOY="path/to/config.json"

  stub aws \
    "ecr get-login --no-include-email : echo true"

  stub docker \
    "run --rm --tty -v /plugin:/app -w /app 909551307430.dkr.ecr.us-east-1.amazonaws.com/ecs-toolkit:latest deploy -c path/to/config.json --ci : exit 1"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "ecs-deploy Buildkite plugin failed: deploy"

  unstub aws
  unstub docker
}

@test "A validate config is passed to the validate command" {
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_PLUGIN_ECS_DEPLOY_VALIDATE="path/to/config.json"

  stub aws \
    "ecr get-login --no-include-email : echo true"

  stub docker \
    "run --rm --tty -v /plugin:/app -w /app 909551307430.dkr.ecr.us-east-1.amazonaws.com/ecs-toolkit:latest validate -c path/to/config.json : exit 1"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "ecs-deploy Buildkite plugin failed: validate"

  unstub aws
  unstub docker
}
