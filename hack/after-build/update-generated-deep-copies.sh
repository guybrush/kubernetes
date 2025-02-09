#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/../..
source "${KUBE_ROOT}/hack/lib/init.sh"

kube::golang::setup_env

gendeepcopy=$(kube::util::find-binary "gendeepcopy")

function result_file_name() {
	local version=$1
	if [ "${version}" == "api" ]; then
		echo "pkg/api/deep_copy_generated.go"
	else
		echo "pkg/api/${version}/deep_copy_generated.go"
	fi
}

function generate_version() {
	local version=$1
	local TMPFILE="/tmp/deep_copy_generated.$(date +%s).go"

	echo "Generating for version ${version}"

	sed 's/YEAR/2015/' hack/boilerplate/boilerplate.go.txt > $TMPFILE
	cat >> $TMPFILE <<EOF
package ${version}

// AUTO-GENERATED FUNCTIONS START HERE
EOF

	"${gendeepcopy}" -v "${version}" -f - -o "${version}=" >>  "$TMPFILE"

	cat >> "$TMPFILE" <<EOF
// AUTO-GENERATED FUNCTIONS END HERE
EOF

	gofmt -w -s "$TMPFILE"
	mv "$TMPFILE" `result_file_name ${version}`
}

function generate_deep_copies() {
  local versions="api v1"
  # To avoid compile errors, remove the currently existing files.
  for ver in ${versions}; do
    rm -f `result_file_name ${ver}`
  done
  apiVersions=""
  for ver in ${versions}; do
    # Ensure that the version being processed is registered by setting
    # KUBE_API_VERSIONS.
    if [ "${ver}" != "api" ]; then
      apiVersions="${ver}"
    fi
    KUBE_API_VERSIONS="${apiVersions}" generate_version "${ver}"
  done
}

generate_deep_copies

# ex: ts=2 sw=2 et filetype=sh
