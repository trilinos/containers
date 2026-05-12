#/bin/bash

GCC_VERSION=14

BUILDER=$(which podman 2> /dev/null)
if [[ "${BUILDER}" == "" ]]; then
  BUILDER=$(which docker 2> /dev/null)
fi
if [[ "${BUILDER}" == "" ]]; then
  echo "No podman or docker found in PATH. Please install one of them."
  exit 1
fi

nohup ${BUILDER} build \
        --build-arg=compiler_version="@${GCC_VERSION}" \
        -t gcc-${GCC_VERSION}-trilinos-env:${USER}-test . \
  &> gcc-${GCC_VERSION}-trilinos-env.output &

