#!/bin/bash
# Script to check Drake build status on ARM64 containers

echo "Checking Drake installation status..."

# Check if we're on ARM64
if [ "$(uname -m)" = "aarch64" ]; then
    echo "Running on ARM64 architecture"
    
    # Check if Drake is already installed
    if [ -d "/opt/drake" ] && [ -f "/opt/drake/lib/python3.10/site-packages/pydrake/__init__.py" ]; then
        echo "✅ Drake is fully installed and ready to use"
        export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
        python3 -c "import pydrake; print(f'PyDrake version: {pydrake.__version__}')" 2>/dev/null || echo "⚠️  Drake installed but Python import failed"
    elif [ -f "/tmp/drake_build.log" ]; then
        echo "🔄 Drake build in progress..."
        echo "Last few lines from build log:"
        tail -5 /tmp/drake_build.log
        echo ""
        echo "To monitor full progress: tail -f /tmp/drake_build.log"
    else
        echo "❌ Drake build not started. Restart the container to trigger the build."
    fi
else
    echo "Running on x86_64 architecture"
    if [ -d "/opt/drake" ]; then
        echo "✅ Drake binary is installed and ready to use"
        export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
        python3 -c "import pydrake; print(f'PyDrake version: {pydrake.__version__}')" 2>/dev/null || echo "⚠️  Drake installed but Python import failed"
    else
        echo "❌ Drake not found"
    fi
fi