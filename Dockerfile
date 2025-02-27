FROM python:3.11-slim-bullseye AS builder

# Set libiec61850 version as a build argument with default value
ARG LIBIEC61850_VERSION=v1.6

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    swig \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Clone libiec61850 with specified version
RUN echo "Building libiec61850 version: $LIBIEC61850_VERSION" && \
    git clone --depth 1 --branch $LIBIEC61850_VERSION https://github.com/mz-automation/libiec61850.git

# Build libiec61850 with Python bindings
RUN cd libiec61850 && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_PYTHON_BINDINGS=ON .. && \
    make -j$(nproc) && \
    make install

# Extract version number without 'v' prefix for Python package
RUN PACKAGE_VERSION=$(echo $LIBIEC61850_VERSION | sed 's/^v//').0 && \
    echo "Python package version: $PACKAGE_VERSION"

# Create a Python package for pyiec61850
WORKDIR /build/pyiec61850-package

# Create package structure
RUN mkdir -p pyiec61850

# Create setup.py file with version extracted from build arg
RUN PACKAGE_VERSION=$(echo $LIBIEC61850_VERSION | sed 's/^v//').0 && \
    echo 'from setuptools import setup, find_packages' > setup.py && \
    echo '' >> setup.py && \
    echo 'setup(' >> setup.py && \
    echo '    name="pyiec61850",' >> setup.py && \
    echo "    version=\"$PACKAGE_VERSION\"," >> setup.py && \
    echo '    packages=find_packages(),' >> setup.py && \
    echo '    package_data={' >> setup.py && \
    echo '        "pyiec61850": ["*.so", "*.py", "lib*.so*"],' >> setup.py && \
    echo '    },' >> setup.py && \
    echo '    include_package_data=True,' >> setup.py && \
    echo "    description=\"Python bindings for libiec61850 $LIBIEC61850_VERSION\"," >> setup.py && \
    echo '    author="Your Name",' >> setup.py && \    
    echo '    url="https://github.com/f0rw4rd/pyiec61850",' >> setup.py && \
    echo '    python_requires=">=3.6",' >> setup.py && \
    echo ')' >> setup.py

# Copy the built pyiec61850 module
RUN cp -r /usr/lib/python3/dist-packages/pyiec61850/* pyiec61850/ || \
    cp -r /usr/lib/python3.*/site-packages/pyiec61850/* pyiec61850/ || \
    cp -r /build/libiec61850/build/pyiec61850/* pyiec61850/

# Copy the shared library into the package directory
RUN cp /usr/lib/libiec61850.so* pyiec61850/

# Create package initialization file with library loader
RUN echo "\"\"\"Python bindings for libiec61850 $LIBIEC61850_VERSION\"\"\"" > pyiec61850/__init__.py && \
    echo "import os" >> pyiec61850/__init__.py && \
    echo "import sys" >> pyiec61850/__init__.py && \
    echo "# Add the package directory to LD_LIBRARY_PATH through ctypes.util search path" >> pyiec61850/__init__.py && \
    echo "_package_dir = os.path.dirname(os.path.abspath(__file__))" >> pyiec61850/__init__.py && \
    echo "os.environ['LD_LIBRARY_PATH'] = _package_dir + os.pathsep + os.environ.get('LD_LIBRARY_PATH', '')" >> pyiec61850/__init__.py && \
    echo "# Also update sys.path to ensure our shared library can be found" >> pyiec61850/__init__.py && \
    echo "if _package_dir not in sys.path:" >> pyiec61850/__init__.py && \
    echo "    sys.path.append(_package_dir)" >> pyiec61850/__init__.py

# Create wheel package
RUN python3 setup.py bdist_wheel

# Create final stage to collect the wheel package
FROM python:3.11-slim-bullseye

# Pass the version through to the final stage
ARG LIBIEC61850_VERSION=v1.6

WORKDIR /wheels

# Copy wheel package from builder stage
COPY --from=builder /build/pyiec61850-package/dist/*.whl /wheels/

# Create a simple installation test script
RUN echo '#!/bin/bash' > /wheels/test_install.sh && \
    echo 'pip install pyiec61850*.whl && \\' >> /wheels/test_install.sh && \
    echo "python -c \"import pyiec61850; print('pyiec61850 $LIBIEC61850_VERSION successfully installed')\"" >> /wheels/test_install.sh && \
    chmod +x /wheels/test_install.sh

# Create README
RUN echo "Python Wheel for libiec61850 $LIBIEC61850_VERSION" > /wheels/README.txt && \
    echo '' >> /wheels/README.txt && \
    echo 'Installation:' >> /wheels/README.txt && \
    echo '   pip install pyiec61850-*.whl' >> /wheels/README.txt && \
    echo '' >> /wheels/README.txt && \
    echo 'Or run the test script:' >> /wheels/README.txt && \
    echo '   ./test_install.sh' >> /wheels/README.txt

CMD ["bash", "-c", "echo 'Python wheel for libiec61850 is available in /wheels directory. Run: ./test_install.sh to verify installation.'"]