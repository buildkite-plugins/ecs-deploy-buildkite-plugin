#!/bin/bash
set -euo pipefail

PLUGIN_PREFIX="ECS_DEPLOY"

# Reads either a value or a list from the given env prefix
function prefix_read_list() {
  local prefix="$1"
  local parameter="${prefix}_0"

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      echo "${!parameter}"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    echo "${!prefix}"
  fi
}

# Reads either a value or a list from plugin config
function plugin_read_list() {
  prefix_read_list "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}


# Reads either a value or a list from plugin config into a global result array
# Returns success if values were read
function prefix_read_list_into_result() {
  local prefix="$1"
  local parameter="${prefix}_0"
  result=()

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      result+=("${!parameter}")
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    result+=("${!prefix}")
  fi

  [ ${#result[@]} -gt 0 ] || return 1
}

# Reads either a value or a list from plugin config
function plugin_read_list_into_result() {
  prefix_read_list_into_result "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}

# Deregisters task definitions that are not the current one
deregister_old_task_definitions() {
  local task_family=$1
  local task_revision=$2

  echo "--- :ecs: Fetching old task definitions to de-register"
  echo "$task_family"
  # Fetch all `ACTIVE` task definitions for the family
  all_active_task_defs=$(aws ecs list-task-definitions \
    --family-prefix "${task_family}" \
    --query 'taskDefinitionArns[]' \
    --output text)

  # Array
  readarray -t active_task_defs <<<"$all_active_task_defs"

  # Remove the current task definition from the list
  for i in "${!active_task_defs[@]}"; do
    if [[ "${active_task_defs[$i]}" == *":${task_revision}"* ]]; then
      unset 'active_task_defs[$i]'
    fi
  done

  # De-register the old task definitions
  for task_def in "${active_task_defs[@]}"; do
    echo "Deregistering $task_def"
    aws ecs deregister-task-definition --task-definition "$task_def"
  done
}