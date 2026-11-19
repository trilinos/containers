# trilinos-containers

The registry for Trilinos images can be found here:

[Trilinos Container Registry](https://gitlab-ex.sandia.gov/trilinos-project/trilinos-containers/container_registry)

## Building Trilinos containers

Two methods of building a container image:
- use the `build.sh` script located next to the `Dockerfile` in the `dockerfiles` directory
- use the `deploy.py` script to build a pre-configured image

NOTE: Building these containers within the SRN requires additional changes. Please contact the Trilinos Framework team for guidance.

To see available pre-configured image options with `deploy.py`:
```
python deploy.py --list
```

Then build the pre-configured image with:
```
python deploy.py --skip-login <configuration_name>
```

Images built using the `deploy.py` script will be tagged with our repository URL, but it will not have been pushed to the repository due to the `--skip-login`.

Additionally, the images built will be tagged according to the last commit date of the `Dockerfile` used.

```
registry-ex.sandia.gov/trilinos-project/trilinos-containers/production/ubi8-gcc-10.3.0-openmpi-4.1.6:20250130
```

## Using pre-built Trilinos container images

In order to pull a pre-built Trilinos image, you must be on a Sandia network to access the registry. Logging in to the registry is not required if you're on the Sandia network.

1. Pull down the image:
```
podman pull registry-ex.sandia.gov/trilinos-project/trilinos-containers/production/ubi9-clang-19.1.7-openmpi-4.1.6:20261117
```

## Information about your container

The `AT2_IMAGE` environment variable should be set and contain the name of the image.
This should be helpful when debugging or reproducing problems.
