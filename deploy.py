#!/usr/bin/env python3

import argparse
import os
import subprocess

REGISTRY = "registry-ex.sandia.gov/trilinos-project/trilinos-containers"

DEPLOYS = [
    {
        "image_name": "ubi8-gcc-12.3.0-openmpi-4.1.6",
        "dockerfile": "gnu-openmpi",
        "build_args": {"compiler_version": "@12.3.0", "mpi_version": "@4.1.6"},
        "production": False,
    },
    {
        "image_name": "ubi8-gcc-10.4.0-openmpi-4.1.6",
        "dockerfile": "gnu-openmpi",
        "build_args": {"compiler_version": "@10.4.0", "mpi_version": "@4.1.6"},
        "production": True,
    },
    {
        "image_name": "ubi8-cuda-11.4.2-gcc-10.4.0-openmpi-4.1.6",
        "dockerfile": "cuda-gnu-openmpi",
        "build_args": {"compiler_version": "@10.4.0", "mpi_version": "@4.1.6", "cuda_version": "@11.4.2"},
        "production": True,
    },
    {
        "image_name": "ubi8-cuda-12.4.1-gcc-10.4.0-openmpi-4.1.6",
        "dockerfile": "cuda-gnu-openmpi",
        "build_args": {"compiler_version": "@10.4.0", "mpi_version": "@4.1.6", "cuda_version": "@12.4.1"},
        "production": False,
    },
    {
        "image_name": "ubi8-gcc-8.3.0-serial",
        "dockerfile": "gnu-serial",
        "build_args": {"compiler_version": "@8.3.0"},
        "production": True,
    },
    {
        "image_name": "ubi10-gcc-14",
        "dockerfile": "gnu-ubi10",
        "build_args": {"compiler_version": "@14"},
        "production": False,
    },
    {
        "image_name": "ubi8-python-3.9",
        "dockerfile": "python",
        "build_args": {},
        "production": True,
    },
    {
        "image_name": "ubi8-oneapi-2024.1.0",
        "dockerfile": "oneapi",
        "build_args": {"compiler_version": "@2024.1.0"},
        "production": True,
    },
    {
        "image_name": "ubi9-clang-19.1.6-openmpi-4.1.6",
        "dockerfile": "clang-openmpi",
        "build_args": {"compiler_version": "@19.1.6", "mpi_version": "@4.1.6"},
        "production": True,
    },
]


def list_container_images(gitlab_url="https://gitlab-ex.sandia.gov", project_id=3512):
    """
    List container images in a private GitLab repository.

    Args:
    gitlab_url (str): The URL of your GitLab instance.
    project_id (int): The ID of your project.

    Returns:
    list: A list of container image locations for all tags.
    """
    # If we're not logging in just return an empty list
    if args.skip_login:
        return []

    import gitlab

    gl = gitlab.Gitlab(gitlab_url)
    project = gl.projects.get(project_id)
    repos = project.repositories.list()
    image_list = [tag.location for repo in repos for tag in repo.tags.list(iterator=True)]

    return image_list


parser = argparse.ArgumentParser()
parser.add_argument("IMAGES", nargs="*")
parser.add_argument("--skip-login", action="store_true", help="Skip registry login")
args = parser.parse_args()

repo_root = os.path.abspath(os.path.dirname(__file__))

if not args.skip_login:
    subprocess.check_call(
        [
            "docker",
            "login",
            "-u",
            "gitlab+deploy-token-23",
            "-p",
            os.environ["AT2_BUILD_TOKEN"],
            "registry-ex.sandia.gov",
        ]
    )

date_format = "%Y%m%d"
os.chdir(repo_root)

if args.IMAGES:
    deploys = [x for x in DEPLOYS if x["image_name"] in args.IMAGES]
else:
    deploys = DEPLOYS

for image in deploys:
    dockerfile = os.path.join(repo_root, "dockerfiles", image["dockerfile"])
    path = dockerfile + "/Dockerfile"
    # get the timestamp from the Dockerfile commit (YYYYMMDD)
    dockerfile_ts = (
        subprocess.check_output(
            [
                "git",
                "--no-pager",
                "log",
                "-1",
                "--format=%cd",
                f"--date=format:{date_format}",
                "--",
                path,
            ]
        )
        .decode()
        .strip()
    )
    if not dockerfile_ts:
        dockerfile_ts = "local"
    build_args = [k + "=" + v for k, v in image["build_args"].items()]
    tag = (
        REGISTRY
        + ("/production/" if image["production"] else "/experimental/")
        + image["image_name"]
        + ":"
        + dockerfile_ts
    )
    if tag in list_container_images():
        print(f"tag {tag} already exists in container registry, skipping build")
        continue
    build_args.append(f"AT2_image_fullpath={tag}")
    build_args.append(f"AT2_image={image['image_name']}")
    print(f"Building Dockerfile '{dockerfile}' with args {build_args}")
    print(f"Tagging as {tag}")
    f = []
    for e in build_args:
        f.append("--build-arg")
        f.append(e)
    try:
        subprocess.check_call(["podman", "build", "--tag", tag] + f + [dockerfile])
    except subprocess.CalledProcessError as e:
        print(f"check_call() returned {e.returncode}")
        continue
    if not args.skip_login:
        subprocess.check_call(["podman", "push", tag])
        latest_tag = (
            REGISTRY + ("/production/" if image["production"] else "/experimental/") + image["image_name"] + ":latest"
        )
        subprocess.check_call(["podman", "push", tag, latest_tag])
