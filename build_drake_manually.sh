#!/bin/bash
# Manual Drake build script for ARM64 containers

echo "Starting manual Drake build for ARM64..."

# Check if we're in ARM64 container
if [ "$(uname -m)" != "aarch64" ]; then
    echo "❌ This script is only for ARM64 containers"
    exit 1
fi

# Check if Drake is already built
if [ -d "/opt/drake" ] && [ -f "/opt/drake/lib/python3.10/site-packages/pydrake/__init__.py" ]; then
    echo "✅ Drake is already installed"
    export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
    python3 -c "import pydrake; print(f'PyDrake version: {pydrake.__version__}')"
    exit 0
fi

echo "🔄 Building Drake from source (this will take 30-60 minutes)..."
echo "Progress will be logged to /tmp/drake_build_manual.log"

(
    cd /tmp/drake-src
    echo "$(date): Starting manual Drake build" > /tmp/drake_build_manual.log
    
    echo "Installing Python dependencies..." >> /tmp/drake_build_manual.log
    pip install pybind11 numpy scipy matplotlib >> /tmp/drake_build_manual.log 2>&1
    
    echo "Configuring Bazel for ARM64..." >> /tmp/drake_build_manual.log
    echo 'build --cpu=arm64' > user.bazelrc
    echo 'build --host_cpu=arm64' >> user.bazelrc
    
    echo "Building PyDrake bindings..." >> /tmp/drake_build_manual.log
    bazel build //bindings/pydrake/... >> /tmp/drake_build_manual.log 2>&1
    
    echo "Installing Drake..." >> /tmp/drake_build_manual.log
    mkdir -p /opt/drake
    bazel run //:install -- /opt/drake >> /tmp/drake_build_manual.log 2>&1
    
    echo "Setting up Python environment..." >> /tmp/drake_build_manual.log
    export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
    echo 'export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"' >> /home/developer/.bashrc
    
    echo "Validating PyDrake installation..." >> /tmp/drake_build_manual.log
    if python3 -c "import pydrake; print('PyDrake installed successfully')" >> /tmp/drake_build_manual.log 2>&1; then
        echo "$(date): Drake build completed successfully!" >> /tmp/drake_build_manual.log
        echo "✅ Drake build completed successfully!"
    else
        echo "$(date): PyDrake installation failed" >> /tmp/drake_build_manual.log
        echo "❌ PyDrake installation failed - check /tmp/drake_build_manual.log"
    fi
) &

BUILD_PID=$!
echo "Build started in background (PID: $BUILD_PID)"
echo "Monitor progress with: tail -f /tmp/drake_build_manual.log"
echo "Wait for completion with: wait $BUILD_PID"