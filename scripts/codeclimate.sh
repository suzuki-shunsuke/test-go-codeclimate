#!/usr/bin/env bash

set -eu
set -x
set -o pipefail

cd "$(dirname "$0")/.."

cc-test-reporter before-build

codeclimate_dir=.codeclimate
mkdir -p "$codeclimate_dir"

for d in $(go list ./...); do
  echo "package: $d" >&2
  package_dir="$codeclimate_dir/$d"
  profile="$package_dir/profile.txt"
  coverage="$package_dir/coverage.json"
  mkdir -p "$package_dir"
  go test -race -coverprofile="$profile" -covermode=atomic "$d"
  if [ "$(wc -l < "$profile")" -eq 1 ]; then
    continue
  fi
  cc-test-reporter format-coverage -t gocov -p "github.com/suzuki-shunsuke/test-go-codeclimate" -o "$coverage" "$profile"
done

result=$codeclimate_dir/codeclimate.total.json
# shellcheck disable=SC2046
cc-test-reporter sum-coverage $(find "$codeclimate_dir" -name coverage.json) -o "$result"
cc-test-reporter upload-coverage -i "$result"
