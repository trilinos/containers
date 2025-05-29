#/bin/bash
export CLANG_VERSION=19.1.6
export OPENMPI_VERSION=4.1.6

nohup podman build \
        --build-arg=compiler_version="@${CLANG_VERSION}" \
        --build-arg=mpi_version="@${OPENMPI_VERSION}" \
        -t clang-${CLANG_VERSION}-openmpi-${OPENMPI_VERSION}-trilinos-env:${USER}-test . \
  &> clang-${CLANG_VERSION}-openmpi-${OPENMPI_VERSION}-trilinos-env.output &

