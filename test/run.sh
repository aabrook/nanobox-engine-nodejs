#!/bin/bash
#
# Run an individual test.
#
# $1 = test
#
# Example: ./run.sh lib/general_test.bats

file=$1
test_dir="$(dirname $(readlink -f $BASH_SOURCE))"
tests_dir="${test_dir}/tests"
engine_dir="$(dirname ${test_dir})"

# Ensure an argument was provided
if [[ $# -lt 1 ]]; then
  echo "Fatal: Must provide a test file as an argument"
  exit 1
fi

# Ensure the argument provided is a path to a file
if [[ ! -f ${tests_dir}/${file} ]]; then
  echo "Fatal: Test provided does not exist in tests (${file})"
  exit 1
fi

# Ensure the test is a .bats test file
filename=$(basename "${file}")
extension="${filename##*.}"

if [[ ! "$extension" = "bats" ]]; then
  echo "Fatal: Test provided is not a bats file (${file})"
  exit 1
fi

echo "+> Running test (${file}):"

# Run the test directly in a docker container
docker run \
  -t \
  --privileged=true \
  --workdir=/test \
  --volume=${test_dir}/:/test \
  --volume=${engine_dir}/:/engine \
  nanobox/build \
  /test/bats/bin/bats \
    --pretty \
    /test/tests/${file} \
      2>&1 \
        | (grep '\S' || echo "") \
          | sed -e 's/\r//g;s/^/   /'

# test the exit code
if [[ "${PIPESTATUS[0]}" != "0" ]]; then
  echo "   [!] FAILED"
  exit 1
else
  echo "   [√] SUCCESS"
fi
