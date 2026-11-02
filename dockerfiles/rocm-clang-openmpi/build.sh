#!/bin/bash

set -euo pipefail

ROCM_VERSION=7.2.1
COMPILER_VERSION=22.0.0 # rocm 7.2.1 provides clang 22.0.0
OPENMPI_VERSION=4.1.6
CPU_ARCH=x86_64_v4
GPU_ARCH=gfx942

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --rocm VER        ROCm version     (default: ${ROCM_VERSION})
  --compiler VER    Clang version    (default: ${COMPILER_VERSION})
  --mpi VER         OpenMPI version  (default: ${OPENMPI_VERSION})
  --cpu-arch ARCH   CPU target       (default: ${CPU_ARCH})
  --gpu-arch ARCH   GPU target       (default: ${GPU_ARCH})
  -h, --help        Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rocm|--compiler|--mpi|--cpu-arch|--gpu-arch)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: $1 requires a value" >&2
        exit 1
      fi
      case "$1" in
        --rocm)     ROCM_VERSION="$2" ;;
        --compiler) COMPILER_VERSION="$2" ;;
        --mpi)      OPENMPI_VERSION="$2" ;;
        --cpu-arch) CPU_ARCH="$2" ;;
        --gpu-arch) GPU_ARCH="$2" ;;
      esac
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

BUILDER=$(command -v podman || command -v docker || true)
if [[ -z "${BUILDER}" ]]; then
  echo "No podman or docker found in PATH. Please install one of them." >&2
  exit 1
fi

TAG=${CPU_ARCH}-${GPU_ARCH}-$(date +%Y%m%d-%H%M%S)
IMAGE=rocm-${ROCM_VERSION}-clang-${COMPILER_VERSION}-openmpi-${OPENMPI_VERSION}:${TAG}
LOG=rocm-clang-openmpi-build.log

nohup "${BUILDER}" build \
        --build-arg=rocm_version="@${ROCM_VERSION}" \
        --build-arg=compiler_version="@${COMPILER_VERSION}" \
        --build-arg=mpi_version="@${OPENMPI_VERSION}" \
        --build-arg=cpu_arch="${CPU_ARCH}" \
        --build-arg=gpu_arch="${GPU_ARCH}" \
        -t "${IMAGE}" \
        . \
  &> "${LOG}" &

echo "Building ${IMAGE} with $(basename "${BUILDER}") (pid $!), logging to ${LOG}"
