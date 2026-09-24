#/bin/bash

ROCM_VERSION=7.2.1
COMPILER_VERSION=22.1.5 # clang
OPENMPI_VERSION=4.1.6
CPU_ARCH=zen4
GPU_ARCH=gfx942

BUILDER=$(which podman 2> /dev/null)
if [[ "${BUILDER}" == "" ]]; then
  BUILDER=$(which docker 2> /dev/null)
fi
if [[ "${BUILDER}" == "" ]]; then
  echo "No podman or docker found in PATH. Please install one of them."
  exit 1
fi

TAG=$(date +%Y%m%d-%H%M%S)

nohup ${BUILDER} build \
        --build-arg=rocm_version="@${ROCM_VERSION}" \
        --build-arg=compiler_version="@${COMPILER_VERSION}" \
        --build-arg=mpi_version="@${OPENMPI_VERSION}" \
        --build-arg=cpu_arch="${CPU_ARCH}" \
        --build-arg=gpu_arch="${GPU_ARCH}" \
        -t rocm-${ROCM_VERSION}-clang-${COMPILER_VERSION}-openmpi-${OPENMPI_VERSION}:${TAG} \
         . \
  &> rocm-clang-openmpi-build.log &

