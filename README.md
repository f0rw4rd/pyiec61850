# pyiec61850

Python bindings for libiec61850, packaged as a Python wheel.

[![Build and Release pyiec61850 Wheel](https://github.com/f0rw4rd/pyiec61850/actions/workflows/build-wheel.yml/badge.svg)](https://github.com/f0rw4rd/pyiec61850/actions/workflows/build-wheel.yml)

This repository provides Python bindings for the [libiec61850](https://github.com/mz-automation/libiec61850) library, which is an open-source implementation of the IEC 61850 standard for communication networks and systems in substations.

## Installation

### Install from GitHub Release

```bash
pip install pyiec61850 --find-links https://github.com/f0rw4rd/pyiec61850/releases/latest/download/
```

### Install directly from GitHub

```bash
pip install git+https://github.com/f0rw4rd/pyiec61850.git
```

### Install from local wheel

```bash
pip install pyiec61850-*.whl
```

## Usage

```python
import pyiec61850

# Example code using the library
# ...
```

## Building from Source

The wheel package is built using Docker:

```bash
docker build -t pyiec61850-builder --build-arg LIBIEC61850_VERSION=v1.6 .
```

To extract the wheel file:

```bash
mkdir -p ./dist
docker create --name wheel-container pyiec61850-builder
docker cp wheel-container:/wheels/. ./dist/
docker rm wheel-container
```

## Supported Versions

This package currently builds wheels for libiec61850 v1.6.

To build a different version, specify the build argument:

```bash
docker build -t pyiec61850-builder --build-arg LIBIEC61850_VERSION=v1.5 .
```

