#!/bin/bash
set -eux

# Move to the project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."
OLD_VERSION="${1}"
NEW_VERSION="${2}"

# This does nothing, just to make craft happy and the changelog running.
echo "Bumping version from ${OLD_VERSION} to ${NEW_VERSION}"
