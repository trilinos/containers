#/bin/bash

ONEAPI_VERSION=2024.2

BUILDER=$(which podman 2> /dev/null)
if [[ "${BUILDER}" == "" ]]; then
  BUILDER=$(which docker 2> /dev/null)
fi
if [[ "${BUILDER}" == "" ]]; then
  echo "No podman or docker found in PATH. Please install one of them."
  exit 1
fi

nohup ${BUILDER} build \
        --build-arg=compiler_version="@${ONEAPI_VERSION}" \
        -t oneapi-${ONEAPI_VERSION}-trilinos-env:${USER}-test . \
  &> oneapi-${ONEAPI_VERSION}-trilinos-env.output &

