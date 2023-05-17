#!/bin/bash
#
# Copyright 2023 Delphix
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
#

set -o xtrace

BASEURL="https://artifactory.delphix.com/artifactory/linux-pkg/go"

function die() {
	echo "$(basename "$0"): $*" >&2
	exit 1
}

function usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0") <version> <destdir>"
	exit 2
}

function cleanup() {
	[[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

[[ $# -gt 3 ]] && usage "too many arguments specified"
[[ $# -lt 3 ]] && usage "too few arguments specified"

VERSION="$1"
PREFIX="$2"
DESTDIR="$3"

GO="go${VERSION}.linux-amd64"

[[ -z "$VERSION" ]] && usage "version not specified."
[[ -z "$PREFIX" ]] && usage "prefix not specified."
[[ -z "$DESTDIR" ]] && usage "destdir not specified."

#
# The full path is required, so DESTDIR can be used after calling "pushd" below.
#
DESTDIR="$(readlink -f "$DESTDIR")"
mkdir -p "${DESTDIR}" || die "'mkdir -p \"${DESTDIR}\"' failed"

trap cleanup EXIT

TEMP_DIR="$(mktemp -d -t delphix-go.XXXXXXX)"
[[ -d "$TEMP_DIR" ]] || die "failed to create temporary directory '$TEMP_DIR'"
pushd "$TEMP_DIR" &>/dev/null || die "'pushd $TEMP_DIR' failed"

wget -nv "${BASEURL}/${GO}.tar.gz" || die "failed to download tarfile"

mkdir -p "${DESTDIR}/${PREFIX}" || die "failed to create target directory"
tar -C "${DESTDIR}/${PREFIX}" -xzf "${GO}.tar.gz" || die "failed to install go"

mkdir -p "${DESTDIR}/${PREFIX}/bin" || die "failed to create symlink directory"
ln -s "${PREFIX}/go/bin/go" "${DESTDIR}/${PREFIX}/bin/go"
ln -s "${PREFIX}/go/bin/gofmt" "${DESTDIR}/${PREFIX}/bin/gofmt"

popd &>/dev/null || die "'popd' failed"
