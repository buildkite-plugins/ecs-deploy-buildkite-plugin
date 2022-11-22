#!/bin/bash

setup_suite() {
  echo '# Installing jq' >&2
  apk --no-cache add jq | sed -e 's/^/# /' >&2
}
