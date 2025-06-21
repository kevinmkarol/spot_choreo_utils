#!/usr/bin/env bash
# Copyright (c) 2025 Boston Dynamics AI Institute LLC. All rights reserved

# Update the developer docker user to match the UID and GID of the host user
# This simplifies permissions with the mounted repo code
usermod -u $UID "developer"
groupmod -g $GID "developer"
chown -R "developer" /usr/local/lib/python3.10/dist-packages/
# Only chown /dev/snd if it exists (Linux only)
if [ -e "/dev/snd" ]; then
    chown -R "developer" /dev/snd
fi

# Set Drake PYTHONPATH before any pip installations
if [ -d "/opt/drake" ]; then
    echo "Setting up Drake environment..."
    export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
    export LD_LIBRARY_PATH="/opt/drake/lib:$LD_LIBRARY_PATH"
    
    # Test PyDrake import
    if python3 -c "import pydrake.common; print('PyDrake is working')" 2>/dev/null; then
        echo "✅ PyDrake is ready to use"
    else
        echo "⚠️  PyDrake import failed - debugging..."
        echo "PYTHONPATH: $PYTHONPATH"
        echo "Checking drake installation:"
        ls -la /opt/drake/lib/python3.10/site-packages/ 2>/dev/null || echo "Drake python packages not found"
    fi
else
    echo "❌ Drake installation not found at /opt/drake"
fi

# Pip install editable dependencies
cd /workspaces/spot_choreo_utils/external/spot_wrapper/
pip install -e .

# Install choreo utils
cd /workspaces/spot_choreo_utils/
pip install -e .

# Install web animator
cd /workspaces/spot_choreo_utils/spot_choreo_utils/web_animator/
bash ./scripts/install_prereqs
pip install -e .

# Create a custom bashrc for developer that sources ROS first, then adds Drake
cat > /home/developer/.bashrc << 'EOF'
# Source global bashrc (includes ROS setup)
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# Drake environment - must be set after ROS setup
export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
export LD_LIBRARY_PATH="/opt/drake/lib:$LD_LIBRARY_PATH"

# Add any other developer-specific settings here
EOF

chown developer:developer /home/developer/.bashrc

cd /workspaces/spot_choreo_utils/spot_choreo_utils/web_animator/spot_web_animator/systems/external/spot_description
rm -rf build install log
ls
source /opt/ros/humble/setup.bash
colcon build
source install/setup.bash
ros2 run xacro xacro -o ./urdf/out/spot.urdf ./urdf/spot.urdf.xacro include_transmissions:=true
ros2 run xacro xacro -o ./urdf/out/standalone_arm.urdf ./urdf/standalone_arm.urdf.xacro include_transmissions:=true gripperless:=true
ros2 run xacro xacro -o ./urdf/out/standalone_gripper.urdf ./urdf/standalone_gripper.urdf.xacro include_transmissions:=true

# Re-add Drake to PYTHONPATH after ROS setup
export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
export LD_LIBRARY_PATH="/opt/drake/lib:$LD_LIBRARY_PATH"

# enter the container as the newly configured user
/bin/bash -c "su - developer"
