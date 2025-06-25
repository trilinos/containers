#/bin/bash
export CLANG_VERSION=19.1.6
export OPENMPI_VERSION=4.1.6

DOCKER_EXEC=$(which podman 2> /dev/null)
if [[ "${DOCKER_EXEC}" == "" ]]; then
  DOCKER_EXEC=$(which docker 2> /dev/null)
fi
if [[ "${DOCKER_EXEC}" == "" ]]; then
  echo "No podman or docker found in PATH. Please install one of them."
  exit 1
fi

nohup ${DOCKER_EXEC} build \
        --build-arg=compiler_version="@${CLANG_VERSION}" \
        --build-arg=mpi_version="@${OPENMPI_VERSION}" \
        -t clang-${CLANG_VERSION}-openmpi-${OPENMPI_VERSION}-trilinos-env:${USER}-test . \
  &> clang-${CLANG_VERSION}-openmpi-${OPENMPI_VERSION}-trilinos-env.output &

