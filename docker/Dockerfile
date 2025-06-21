# Copyright (c) 2025 Boston Dynamics AI Institute LLC. All rights reserved.

# Use Drake's official Docker image as base (with emulation on Apple Silicon)
FROM --platform=linux/amd64 robotlocomotion/drake:1.24.0

USER root
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# Common setup for both architectures
RUN apt-get update && apt-get install -y --no-install-recommends \
  python-is-python3 \
  python3-pip \ 
  vim \
  sudo \
  ffmpeg \
  git \ 
  curl \
  gnupg2 \
  lsb-release \
  ca-certificates

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install ROS2 and Colcon
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2-latest.list
RUN apt-get update && apt-get install -y \
  ros-humble-desktop \
  ros-humble-xacro \
  python3-colcon-common-extensions
RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc

ENV SETUP_DIR="/setup"
RUN mkdir -p /workspaces
RUN mkdir -p $SETUP_DIR

# Drake is already installed in the base image
# Set Drake environment variables (already configured in base image, but ensuring they're set)
ENV DRAKE_INSTALL_DIR=/opt/drake

# Python deps
COPY requirements.txt $SETUP_DIR/requirements.txt
RUN pip install -r $SETUP_DIR/requirements.txt

# Create a non-root user 
ENV NEW_USER="developer"
RUN groupadd -g 1000 $NEW_USER
RUN useradd -d /workspaces/spot_choreo_utils  -s /bin/bash -m $NEW_USER -u 1000 -g 1000 && echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN usermod -aG sudo $NEW_USER
RUN echo "$NEW_USER:ubuntu" | chpasswd

# Setup permissions
RUN chown -R $NEW_USER /workspaces
RUN chown -R $NEW_USER $SETUP_DIR
RUN chown -R $NEW_USER /usr/local/lib/python3.10/dist-packages/
COPY docker/entrypoint.sh $SETUP_DIR/entrypoint.sh

ENTRYPOINT ["/usr/bin/bash", "/setup/entrypoint.sh"]
CMD ["/bin/bash"]
