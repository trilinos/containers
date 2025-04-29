# trilinos-containers

The registry for Trilinos images can be found here:

[Trilinos Container Registry](https://gitlab-ex.sandia.gov/trilinos-project/trilinos-containers/container_registry)

## Building the AT2 containers

Any/all of the various images can be constructed via the python wrapper `deploy.py`:

```
./deploy.py --skip-login ubi8-gcc-10.3.0-openmpi-4.1.6
```

The `--skip-login` flag will prevent the script from logging in and potentially modifying any images in the registry.
Running `deploy.py` with the above arguments will build the `ubi8-gcc-10.3.0-openmpi-4.1.6` configuration; it may take some time to download the spack packages and build the image.
The resulting image will have a YYYYMMDD timestamp of the last commit from the corresponding Dockerfile e.g., `ubi8-gcc-10.3.0-openmpi-4.1.6:20250130`.
Upon completion, you should be able to start the container:

```
podman run --rm -it registry-ex.sandia.gov/trilinos-project/trilinos-containers/production/ubi8-gcc-10.3.0-openmpi-4.1.6:20250130
```

## Using pre-built AT2 containers

1. You need a machine where you can run containers.  You need podman or docker on the machine.  Rhel8 will have podman by default; windows and mac users can install docker and these should work.  Currently all of the containers are built for x86-64 and need to be run on capable hardware.

1. You may need to login to the registry:
```
podman login registry-ex.sandia.gov
username:
password: <your password for gitlab-ex>
```

1. Pull down the image:
```
podman pull registry-ex.sandia.gov/trilinos-project/trilinos-containers/experimental/ubi8-gcc-10.3.0-openmpi-4.1.6:20241118
```

1. To run the container interactively:
```
podman run --rm -it registry-ex.sandia.gov/trilinos-project/trilinos-containers/experimental/ubi8-gcc-10.3.0-openmpi-4.1.6:20241118
```

Once in the container, the environment is already set and it looks like a familiar module environment:

```
[root@aaecb38152fb /]# module list
Currently Loaded Modulefiles:
 1) ccache/4.8.2                      9) mpc/1.3.1-gcc-8.5.0-jdpkpms   17) metis/5.1.0             25) binder/1.3.0
 2) valgrind/3.20.0                  10) gcc/10.3.0-gcc-8.5.0-ikdggsq  18) netcdf-c/4.9.2          26) py-mpi4py/3.1.4
 3) gdb/13.1                         11) openmpi/4.1.6                 19) parallel-netcdf/1.12.3  27) py-numpy/1.26.1
 4) zlib-ng/2.1.4-gcc-8.5.0-4mix3jq  12) cmake/3.27.7                  20) parmetis/4.0.3          28) py-pybind11/2.11.1
 5) zstd/1.5.5-gcc-8.5.0-4okppqr     13) ninja/1.11.1                  21) superlu/5.3.0           29) openblas/0.3.24
 6) binutils/2.41-gcc-8.5.0-xt4vsa7  14) boost/1.83.0                  22) superlu-dist/8.1.2      30) emacs/29.1
 7) gmp/6.2.1-gcc-8.5.0-w7wsbbi      15) cgns/4.4.0                    23) zlib/1.3                31) gh/2.32.1
 8) mpfr/4.2.0-gcc-8.5.0-3d45ev6     16) hdf5/1.14.3                   24) matio/1.5.17
[root@aaecb38152fb /]# echo $CC
/home/runner/spack/opt/spack/linux-rhel8-x86_64/gcc-8.5.0/gcc-10.3.0-ikdggsqaa6iwfrreixba5relam2bd7ki/bin/gcc
[root@aaecb38152fb /]# echo $CXX
/home/runner/spack/opt/spack/linux-rhel8-x86_64/gcc-8.5.0/gcc-10.3.0-ikdggsqaa6iwfrreixba5relam2bd7ki/bin/g++
[root@aaecb38152fb /]# echo $MPICC
/home/runner/spack/opt/spack/linux-rhel8-x86_64/gcc-10.3.0/openmpi-4.1.6-bbzeyro4q6y2lphvueezj6kg6cpmcbbc/bin/mpicc
[root@aaecb38152fb /]# echo $MPICXX
/home/runner/spack/opt/spack/linux-rhel8-x86_64/gcc-10.3.0/openmpi-4.1.6-bbzeyro4q6y2lphvueezj6kg6cpmcbbc/bin/mpic++
[root@aaecb38152fb /]# which cmake
/home/runner/spack/opt/spack/linux-rhel8-x86_64/gcc-10.3.0/cmake-3.27.7-zxyov77bfwd7e6r5ynkwypcwqljlymw6/bin/cmake
```

## To build another image on top of this image:

 Create a Dockerfile that uses it:

```
from registry-ex.sandia.gov/trilinos-project/trilinos-containers/experimental/ubi8-gcc-10.3.0-openmpi-4.1.6:20241118

RUN <whatever commands you want>
```

## Information about your container

The `AT2_IMAGE` environment variable should be set and contain the name of the image.
This should be helpful when debugging or reproducing problems.
