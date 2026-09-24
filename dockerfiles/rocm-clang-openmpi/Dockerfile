# Pinned to amd64 ubi9.7-1778044007
ARG base_image=registry.access.redhat.com/ubi9/ubi@sha256:f9a905cb655db94303bb2a37f150256a4d24c5ef7da07071888b41b52b588e5b
FROM ${base_image}

# Disable all host repositories so that we're only using things from UBI
# (in the event that you're building a UBI container on a RHEL host, RedHat
# tries to 'help' and let you use your subscription inside the container)
RUN rm -rf /etc/rhsm-host
RUN yum -y --setopt=tsflags=nodocs update && yum clean all

RUN yum -y install gcc gcc-c++ gcc-gfortran libatomic xz bzip2 patch diffutils file make git python python3-pip procps gettext unzip libX11-devel environment-modules

# flang needs quadmath.h provided by system gcc, but clang ignores gcc's include directories
RUN ln -s /usr/lib/gcc/x86_64-redhat-linux/*/include/quadmath*.h /usr/include/

RUN useradd runner
USER runner

# Pinned spack to v1.2.2
RUN git clone https://github.com/spack/spack.git /home/runner/spack && cd /home/runner/spack && git checkout 3e19345b6e12f5ff1b874f4059622fc6a1fd804a
RUN echo -e "export SPACK_ROOT=/home/runner/spack\nsource /home/runner/spack/share/spack/setup-env.sh\n" >> /home/runner/.bashrc
RUN bash -l -c "spack config add config:build_jobs:64"
# Pinned spack-packages to v2026.06.0
RUN bash -l -c "spack repo update builtin --scope defaults --commit d4f7c711a6a42f1c4d551c8fd10fce9a11340a81"
RUN bash -l -c "spack bootstrap now"

ARG rocm_version=
ARG compiler_version=
ARG cpu_arch=
ARG gpu_arch=

RUN bash -l -c "spack compiler find"
RUN bash -l -c "\
    spack -C /home/runner config add 'concretizer:targets:host_compatible:false'"
RUN bash -l -c "\
    (spack -C /home/runner install --deprecated llvm-amdgpu${rocm_version}+link_llvm_dylib target=${cpu_arch} || true) && \
    spack -C /home/runner install --deprecated llvm-amdgpu${rocm_version}+link_llvm_dylib target=${cpu_arch} && \
    spack clean --downloads"

ARG mpi_version=

RUN mkdir /home/runner/environment

RUN LLVM_PREFIX=$(/home/runner/spack/bin/spack location -i llvm-amdgpu${rocm_version}+link_llvm_dylib) && \
cat > /home/runner/environment/spack.yaml <<EOF
spack:
  include:
  - modules.yaml
  packages:
    llvm-amdgpu:
      buildable: false
      externals:
      - spec: llvm-amdgpu${rocm_version}+link_llvm_dylib target=${cpu_arch}
        prefix: ${LLVM_PREFIX}
        extra_attributes:
          compilers:
            c: ${LLVM_PREFIX}/bin/clang
            cxx: ${LLVM_PREFIX}/bin/clang++
            fortran: ${LLVM_PREFIX}/bin/flang
    c:
      require: ['llvm-amdgpu${rocm_version}']
    cxx:
      require: ['llvm-amdgpu${rocm_version}']
    fortran:
      require: ['llvm-amdgpu${rocm_version}']
    all:
      variants: ['amdgpu_target=${gpu_arch}']
      target: [${cpu_arch}]
  definitions:
  - rocm_pkgs:
    - hip
    - rocm-smi-lib
    - rocblas ~hipblaslt
    - rocsolver
    - rocsparse
  specs:
  - matrix:
    - [\$rocm_pkgs]
    - ['${rocm_version}']
  - openblas
  - openmpi${mpi_version}
  - boost +program_options+system
  - hdf5 +hl
  - metis
  - netcdf-c +parallel-netcdf
  - parallel-netcdf
  - parmetis
  - superlu-dist@5.4.0
  - superlu@5
  - zlib
  - matio
  - googletest
  - ccache
  - valgrind
  - cmake
  - ninja
  - gh
  view:
    default:
      root: /home/runner/rocm
      exclude:
        - 'openmpi'
        - 'llvm' # only want llvm-amdgpu in view
        - 'rocm-cmake'
  concretizer:
    targets:
      host_compatible: false
    unify: true
EOF

RUN cat >> /home/runner/environment/modules.yaml <<EOF
modules:
  prefix_inspections:
    ./bin:
      - PATH
    ./lib:
    - LIBRARY_PATH
    - LD_LIBRARY_PATH
    ./lib64:
    - LIBRARY_PATH
    - LD_LIBRARY_PATH
    ./include:
    - INCLUDE
    ./man:
      - MANPATH
    ./share/man:
      - MANPATH
    ./share/aclocal:
      - ACLOCAL_PATH
    ./lib/pkgconfig:
      - PKG_CONFIG_PATH
    ./lib64/pkgconfig:
      - PKG_CONFIG_PATH
    ./share/pkgconfig:
      - PKG_CONFIG_PATH
    ./:
      - CMAKE_PREFIX_PATH
  default:
    enable:
      - tcl
    tcl:
      hash_length: 0
      projections:
        all: '{name}/{version}'
      all:
        conflict:
        - '{name}'
        environment:
          set:
            '{name}_ROOT': '{prefix}'
            '{name}_VERSION': '{version}'
            '{name}_BIN': '{prefix.bin}'
            '{name}_INC': '{prefix.include}'
            '{name}_LIB': '{prefix.lib}'
        autoload: none
      blas:
        environment:
          set:
            'BLAS_ROOT': '{prefix}'
            'LAPACK_ROOT': '{prefix}'
      gcc:
        environment:
          set:
            'COMPILER_ROOT': '{prefix}'
      llvm-amdgpu:
        environment:
          set:
            'COMPILER_ROOT': '{prefix}'
EOF

RUN bash -l -c "spack module tcl refresh -y"

RUN echo -e "spack env activate /home/runner/environment\n" >> /home/runner/.bashrc
# LLVM built targeting given cpu_arch located here
RUN bash -l -c "echo \"export MODULEPATH=/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-${cpu_arch}\" >> /home/runner/.bashrc"
# Moduling loading LLVM requires the system GCC runtime located here
#RUN bash -l -c "echo \"export MODULEPATH=\\\${MODULEPATH}:/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-x86_64_v4\" >> /home/runner/.bashrc"
## GCC runtime requires glibc located here
#RUN bash -l -c "echo \"export MODULEPATH=\\\${MODULEPATH}:/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-x86_64\" >> /home/runner/.bashrc"

RUN bash -l -c "spack external find python"
RUN bash -l -c "spack concretize --fresh --force"
# Export spack environment into a Makefile and run
# `make` twice to mimic a retry if a pull from spack mirror fails.
# Perform all the related cleanup under a single RUN to avoid
# including ghost files in the final image layer.
#
# Spack depfile is deprecated and will be removed in v1.4
RUN bash -l -c " \
    cd /home/runner && \
    spack env depfile -o Makefile && \
    (make -j24 || true) && \
    make -j24 && \
    spack clean --downloads && \
    rm Makefile && \
    rm -rf .cache"

ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

CMD [ "/bin/bash" ]

# Image basename (useful for describing image characteristics, e.g. toolchain)
ARG AT2_image=
ENV AT2_IMAGE=${AT2_image}
# Image path as pushed (useful for referencing where to pull the image)
ARG AT2_image_fullpath=
ENV AT2_IMAGE_FULLPATH=${AT2_image_fullpath}

RUN bash -l -c "spack module tcl refresh -y %llvm-amdgpu${rocm_version}"
RUN cat >> /home/runner/.bashrc <<EOF
module load hip
module load rocm-smi-lib
module load rocblas
module load rocsolver
module load rocsparse
module load openblas
module load openmpi
module load ccache
module load boost
module load hdf5
module load metis
module load netcdf-c
module load parallel-netcdf
module load parmetis
module load superlu-dist
module load superlu
module load zlib
module load matio
module load googletest
module load ccache
module load valgrind
module load cmake
module load ninja
module load gh

export CCACHE_NODISABLE=true
export CCACHE_BASEDIR=$HOME
export CCACHE_NOHARDLINK=true
export CCACHE_UMASK=077
export CCACHE_MAXSIZE=100G

if [ -d /ccache-dir ]; then
  export CCACHE_DIR=/ccache-dir
else
  export CCACHE_DIR=$HOME/ccache-dir
  mkdir -p \$CCACHE_DIR
fi
EOF

# Setup artifact Dockerfile in image
ENV AT2_ARTIFACTS_DIR=/home/runner/artifacts
RUN mkdir $AT2_ARTIFACTS_DIR
COPY Dockerfile ${AT2_ARTIFACTS_DIR}/Dockerfile
# Set artifact Dockerfile default arguments as the used build-arguments
RUN sed -i "s/^\(ARG AT2_image=\).*/\1${AT2_image}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s|^\(ARG AT2_image_fullpath=\).*|\1${AT2_image_fullpath}|" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG compiler_version=\).*/\1${compiler_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG mpi_version=\).*/\1${mpi_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG cuda_version=\).*/\1${cuda_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile

USER root
RUN echo -e "source /home/runner/.bashrc" >> /root/.bashrc
