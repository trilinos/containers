FROM registry.access.redhat.com/ubi8:latest

# Disable all host repositories so that we're only using things from UBI
# (in the event that you're building a UBI container on a RHEL host, RedHat
# tries to 'help' and let you use your subscription inside the container)
RUN rm -rf /etc/rhsm-host
RUN yum -y --setopt=tsflags=nodocs update && yum clean all

RUN yum -y install gcc gcc-c++ xz bzip2 patch diffutils file make git python38 procps environment-modules gettext unzip libX11-devel

# FIXME: Remove this someday
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN useradd runner
USER runner

RUN git clone https://github.com/spack/spack.git /home/runner/spack && cd /home/runner/spack && git checkout bd519af8bc62a6f9eea6f4c0fa0bf498a0cc0dfb
RUN echo -e "export SPACK_ROOT=/home/runner/spack\nsource /home/runner/spack/share/spack/setup-env.sh\n" >> /home/runner/.bashrc
RUN bash -l -c "spack config add config:build_jobs:64"
RUN bash -l -c "spack bootstrap now"

ARG compiler_version=

RUN bash -l -c "spack compiler find"
RUN bash -l -c "spack -C /home/runner install --deprecated intel-oneapi-compilers${compiler_version} target=x86_64 || true"
RUN bash -l -c "spack -C /home/runner install --deprecated intel-oneapi-compilers${compiler_version} target=x86_64"

ARG mpi_version=

RUN mkdir /home/runner/environment
# Consider using here-documents once we get to Buildah 1.33.0+
# https://github.com/containers/buildah/issues/3474#issuecomment-1821752538
RUN echo -e "\
spack:\n\
  include:\n\
  - modules.yaml\n\
  definitions:\n\
  - compiler:\n\
    - oneapi${compiler_version}\n\
  - packages:\n\
    - boost@1.84 +program_options+system\n\
    - cgns\n\
    - hdf5 +hl\n\
    - metis\n\
    - netcdf-c +parallel-netcdf\n\
    - parallel-netcdf\n\
    - parmetis\n\
    - superlu@5\n\
    - superlu-dist\n\
    - zlib\n\
    - intel-oneapi-mpi${mpi_version}\n\
    - matio\n\
    - intel-oneapi-mkl\n\
    - fmt\n\
    - unzip\n\
  concretizer:\n\
    unify: when_possible\n\
  specs:\n\
  - matrix:\n\
    - [\$packages]\n\
    - [\$%compiler]\n\
  - ccache%gcc\n\
  - gdb\n\
  - valgrind\n\
  - cmake\n\
  - ninja\n\
  - emacs\n\
  - gh\n\
  view: false\n\
  packages:\n\
    all:\n\
      target: [x86_64]\n" > /home/runner/environment/spack.yaml

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
      intel-oneapi-compilers:\n\
        environment:\n\
          set:\n\
            'COMPILER_ROOT': '{prefix}'\n\
      llvm:\n\
        environment:\n\
          set:\n\
            'COMPILER_ROOT': '{prefix}'" >> /home/runner/environment/modules.yaml

RUN bash -l -c "spack module tcl refresh -y"

RUN rm -rf /home/runner/.spack
RUN bash -l -c "spack bootstrap now"

RUN echo -e "spack env activate /home/runner/environment\n" >> /home/runner/.bashrc
RUN bash -l -c "echo \"export MODULEPATH=/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-x86_64\" >> /home/runner/.bashrc"
RUN bash -l -c "module load intel-oneapi-compilers && spack compiler find $COMPILER_ROOT"

RUN bash -l -c "spack concretize"
RUN bash -l -c "cd /home/runner && spack env depfile -o Makefile"
# Just in case a mirror fails to pull, retry the spack install so that we can preserve
# all of the packages that did build successfully
RUN bash -l -c "cd /home/runner && make -j6 || true"
RUN bash -l -c "cd /home/runner && make -j6"
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

RUN bash -l -c "spack module tcl refresh -y %intel-oneapi-compilers${compiler_version}"
RUN echo -e "\
module load ccache\n\
module load valgrind\n\
module load gdb\n\
module load intel-oneapi-compilers\n\
module load intel-oneapi-mpi\n\
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
module load intel-oneapi-mkl\n\
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
