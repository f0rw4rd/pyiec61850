import os
import subprocess
import sys
from setuptools import setup, find_packages, Extension
from setuptools.command.build_ext import build_ext


class BuildExtInDocker(build_ext):
    """Build the extension inside Docker and extract the wheel."""

    def run(self):
        # Check if Docker is available
        try:
            subprocess.check_call(["docker", "--version"], stdout=subprocess.PIPE)
        except (subprocess.SubprocessError, FileNotFoundError):
            print(
                "Docker is required to build this package. Please install Docker and try again."
            )
            sys.exit(1)

        # Define libiec61850 version
        libiec61850_version = os.environ.get("LIBIEC61850_VERSION", "v1.6")

        # Build Docker image
        subprocess.check_call(
            [
                "docker",
                "build",
                "-t",
                "pyiec61850-builder",
                "--build-arg",
                f"LIBIEC61850_VERSION={libiec61850_version}",
                ".",
            ]
        )

        # Create container
        container_id = (
            subprocess.check_output(["docker", "create", "pyiec61850-builder"])
            .decode("utf-8")
            .strip()
        )

        try:
            # Create dist directory
            os.makedirs("dist", exist_ok=True)

            # Copy wheel from container
            subprocess.check_call(
                ["docker", "cp", f"{container_id}:/wheels/.", "dist/"]
            )

            # Find the wheel file
            wheel_file = None
            for file in os.listdir("dist"):
                if file.endswith(".whl"):
                    wheel_file = os.path.join("dist", file)
                    break

            if wheel_file:
                print(f"Built wheel: {wheel_file}")
                # No need to install the extensions as we've built the wheel
                self.extensions = []
            else:
                print("No wheel file found in the Docker container.")
                sys.exit(1)

        finally:
            # Remove container
            subprocess.check_call(["docker", "rm", container_id])


setup(
    name="pyiec61850",
    version="1.6.0",  # This will be overridden by the Docker build
    description="Python bindings for libiec61850",
    author="Your Name",
    author_email="your.email@example.com",
    url="https://github.com/f0rw4rd/pyiec61850",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.6",
    cmdclass={
        "build_ext": BuildExtInDocker,
    },
    ext_modules=[
        Extension(name="dummy", sources=["dummy.c"]),
    ],
    package_data={
        "pyiec61850": ["*.so", "*.py"],
    },
)
