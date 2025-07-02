FROM mambaorg/micromamba:debian12

# Switch to root to install packages
USER root

# Update package lists and install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    gfortran \
    xz-utils \
    bzip2 \
    patch \
    diffutils \
    file \
    make \
    git \
    python3 \
    python3-pip \
    perl \
    procps \
    tcl-dev \
    gettext \
    unzip \
    libx11-dev \
    sudo \
    curl \
    wget \
    lmod \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m runner && usermod -aG sudo runner
USER runner

RUN git clone https://github.com/spack/spack.git /home/runner/spack && cd /home/runner/spack && git checkout develop-2025-01-12

# Set up Spack environment variables
ENV SPACK_ROOT=/home/runner/spack
ENV PATH=$SPACK_ROOT/bin:$PATH

RUN echo -e "export SPACK_ROOT=/home/runner/spack\nsource /home/runner/spack/share/spack/setup-env.sh\n" >> /home/runner/.bashrc
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack config add config:build_jobs:64"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack bootstrap now"

ARG compiler_version=

RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack compiler find"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack -C /home/runner install llvm+clang+lld${compiler_version} target=x86_64 > /dev/null & spack -C /home/runner install llvm+clang+lld${compiler_version} target=x86_64 || true"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack -C /home/runner install llvm+clang+lld${compiler_version} target=x86_64 > /dev/null & spack -C /home/runner install llvm+clang+lld${compiler_version} target=x86_64"

ARG mpi_version=

RUN mkdir /home/runner/environment
# Consider using here-documents once we get to Buildah 1.33.0+
# https://github.com/containers/buildah/issues/3474#issuecomment-1821752538
RUN echo -e "\
spack:\n\
  include:\n\
  - modules.yaml\n\
  packages:\n\
    all:\n\
      require:\n\
      - '%clang${compiler_version}'\n\
      target: [x86_64]\n\
  specs:\n\
  - ccache\n\
  - valgrind\n\
  - cmake\n\
  - ninja\n\
  - boost +program_options+system\n\
  - cgns\n\
  - hdf5 +hl\n\
  - metis\n\
  - netcdf-c +parallel-netcdf\n\
  - parallel-netcdf\n\
  - parmetis\n\
  - superlu-dist@5.4.0\n\
  - superlu@5\n\
  - zlib\n\
  - openmpi${mpi_version}\n\
  - matio\n\
  - openblas\n\
  - fmt\n\
  - emacs\n\
  - gh\n\
  concretizer:\n\
    unify: when_possible\n\
  view: false\n" > /home/runner/environment/spack.yaml

RUN echo -e "\
modules:\n\
  prefix_inspections:\n\
    ./bin:\n\
      - PATH\n\
    ./lib:\n\
    - LIBRARY_PATH\n\
    - LD_LIBRARY_PATH\n\
    ./lib64:\n\
    - LIBRARY_PATH\n\
    - LD_LIBRARY_PATH\n\
    ./include:\n\
    - INCLUDE\n\
    ./man:\n\
      - MANPATH\n\
    ./share/man:\n\
      - MANPATH\n\
    ./share/aclocal:\n\
      - ACLOCAL_PATH\n\
    ./lib/pkgconfig:\n\
      - PKG_CONFIG_PATH\n\
    ./lib64/pkgconfig:\n\
      - PKG_CONFIG_PATH\n\
    ./share/pkgconfig:\n\
      - PKG_CONFIG_PATH\n\
    ./:\n\
      - CMAKE_PREFIX_PATH\n\
  default:\n\
    enable:\n\
      - tcl\n\
    tcl:\n\
      hash_length: 0\n\
      projections:\n\
        all: '{name}/{version}'\n\
      all:\n\
        conflict:\n\
        - '{name}'\n\
        environment:\n\
          set:\n\
            '{name}_ROOT': '{prefix}'\n\
            '{name}_VERSION': '{version}'\n\
            '{name}_BIN': '{prefix.bin}'\n\
            '{name}_INC': '{prefix.include}'\n\
            '{name}_LIB': '{prefix.lib}'\n\
        autoload: none\n\
      blas:\n\
        environment:\n\
          set:\n\
            'BLAS_ROOT': '{prefix}'\n\
            'LAPACK_ROOT': '{prefix}'\n\
      gcc:\n\
        environment:\n\
          set:\n\
            'COMPILER_ROOT': '{prefix}'\n\
      llvm:\n\
        environment:\n\
          set:\n\
            'COMPILER_ROOT': '{prefix}'" >> /home/runner/environment/modules.yaml

RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack module tcl refresh -y"

RUN echo -e "spack env activate /home/runner/environment\n" >> /home/runner/.bashrc
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && echo \"export MODULEPATH=/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-x86_64\" >> /home/runner/.bashrc"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && export FC=\$(type -p gfortran) >> /home/runner/.bashrc"

# Initialize lmod/environment modules - find the correct lmod init script
RUN find /usr -name "lmod" -type d 2>/dev/null || echo "lmod not found in /usr"
RUN find /etc -name "*modules*" 2>/dev/null || echo "modules not found in /etc"
RUN if [ -f /usr/share/lmod/lmod/init/bash ]; then echo "source /usr/share/lmod/lmod/init/bash" >> /home/runner/.bashrc; fi
RUN if [ -f /etc/profile.d/modules.sh ]; then echo "source /etc/profile.d/modules.sh" >> /home/runner/.bashrc; fi

# Skip the module load command for now since lmod may not be properly configured
# RUN bash -c "source /usr/share/lmod/lmod/init/bash && source /home/runner/spack/share/spack/setup-env.sh && module load llvm && spack compiler find --mixed-toolchain $COMPILER_ROOT"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack compiler find"

RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack external find python"

RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack concretize"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && cd /home/runner && spack env depfile -o Makefile"
# Just in case a mirror fails to pull, retry the spack install so that we can preserve
# all of the packages that did build successfully
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && cd /home/runner && make -j6 || true"
RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && cd /home/runner && make -j6"
RUN rm /home/runner/Makefile

ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

CMD [ "/bin/bash" ]

# Image basename (useful for describing image characteristics, e.g. toolchain)
ARG AT2_image=
ENV AT2_IMAGE=${AT2_image}
# Image path as pushed (useful for referencing where to pull the image)
ARG AT2_image_fullpath=
ENV AT2_IMAGE_FULLPATH=${AT2_image_fullpath}

RUN bash -c "source /home/runner/spack/share/spack/setup-env.sh && spack module tcl refresh -y %llvm+clang+lld${compiler_version}"
RUN echo -e "\
module load ccache\n\
module load valgrind\n\
module load llvm\n\
module load openmpi\n\
module load cmake\n\
module load ninja\n\
module load boost\n\
module load cgns\n\
module load hdf5\n\
module load metis\n\
module load netcdf-c\n\
module load parallel-netcdf\n\
module load parmetis\n\
module load superlu\n\
module load superlu-dist\n\
module load zlib\n\
module load matio\n\
module load openblas\n\
module load emacs\n\
module load gh\n\
\n\
export CCACHE_NODISABLE=true\n\
export CCACHE_BASEDIR=$HOME\n\
export CCACHE_NOHARDLINK=true\n\
export CCACHE_UMASK=077\n\
export CCACHE_MAXSIZE=100G\n\
\n\
if [ -d /ccache-dir ]; then\n\
  export CCACHE_DIR=/ccache-dir\n\
else\n\
  export CCACHE_DIR=$HOME/ccache-dir\n\
  mkdir -p \$CCACHE_DIR\n\
fi">> /home/runner/.bashrc

# Setup artifact Dockerfile in image
ENV AT2_ARTIFACTS_DIR=/home/runner/artifacts
RUN mkdir $AT2_ARTIFACTS_DIR
COPY Dockerfile ${AT2_ARTIFACTS_DIR}/Dockerfile
# Set artifact Dockerfile default arguments as the used build-arguments
RUN sed -i "s/^\(ARG AT2_image=\).*/\1${AT2_image}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s|^\(ARG AT2_image_fullpath=\).*|\1${AT2_image_fullpath}|" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG compiler_version=\).*/\1${compiler_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG mpi_version=\).*/\1${mpi_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile

USER root
RUN echo -e "source /home/runner/.bashrc" >> /root/.bashrc
