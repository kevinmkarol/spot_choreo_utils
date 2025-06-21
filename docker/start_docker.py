# Copyright (c) 2025 Boston Dynamics AI Institute LLC. All rights reserved.

import os
import platform
import socket
import subprocess
from argparse import ArgumentParser
from pathlib import Path


def get_repo_root() -> Path:
    """Returns the path to the repo root"""
    return Path(__file__).parent.parent.resolve()


def is_port_available(port: int) -> bool:
    """Check if a port is available for binding"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('', port))
            return True
    except OSError:
        return False


def get_available_port(preferred_port: int, port_name: str) -> int:
    """Get an available port, trying the preferred port first"""
    if is_port_available(preferred_port):
        return preferred_port
    
    # Try alternative ports
    alt_port = preferred_port + 10000  # Try 10000 higher
    if is_port_available(alt_port):
        print(f"Warning: Port {preferred_port} is in use for {port_name}. Using {alt_port} instead.")
        return alt_port
    
    # Find any available port
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        port = s.getsockname()[1]
        print(f"Warning: Port {preferred_port} is in use for {port_name}. Using {port} instead.")
        return port


def build_image(image_name: str) -> None:
    """Build the repo dockerfile"""
    subprocess.run(
        ["docker", "build", ".", "-fdocker/Dockerfile", "-t", image_name], check=True, cwd=get_repo_root().as_posix()
    )


def start_container(image_name: str, container_name: str, detached: bool = False) -> None:
    """Start the repo dockerfile with the code mounted as a volume"""
    repo_root = get_repo_root()
    system = platform.system()

    # Specify run mode
    if detached:
        run_args = ["docker", "run", "-d"]
    else:
        run_args = ["docker", "run", "-it"]
    # Set the conatiner name
    run_args += ["--name", container_name]
    
    # Platform-specific network configuration
    if system == "Linux":
        # Share the network host so browser can interact with localhost servers inside docker
        run_args += ["--net=host"]
    elif system == "Darwin":
        # macOS doesn't support --net=host, use port mapping instead
        # Check and map available ports
        jupyter_port = get_available_port(8888, "Jupyter")
        meshcat_port = get_available_port(7000, "Meshcat")
        frontend_port = get_available_port(3000, "Frontend")
        fastapi_port = get_available_port(8000, "FastAPI")
        
        # Port mappings
        run_args += ["-p", f"{jupyter_port}:8888"]
        run_args += ["-p", f"{meshcat_port}:7000"]
        run_args += ["-p", f"{frontend_port}:3000"]
        run_args += ["-p", f"{fastapi_port}:8000"]
        
        print("\nPort mappings for macOS:")
        print(f"  Jupyter notebook: http://localhost:{jupyter_port}")
        print(f"  Meshcat: http://localhost:{meshcat_port}")
        print(f"  Frontend: http://localhost:{frontend_port}")
        print(f"  FastAPI: http://localhost:{fastapi_port}\n")
    
    # Match current user permissions to user inside docker container
    run_args += ["-e", f"UID={os.getuid()}"]
    run_args += ["-e", f"GID={os.getgid()}"]
    
    # Platform-specific audio configuration
    if system == "Linux":
        # Linux audio device and PulseAudio configuration
        run_args += ["--device", "/dev/snd"]
        # Mount the PulseAudio socket for audio forwarding
        run_args += ["-v", f"/run/user/{os.getuid()}/pulse/native:/run/pulse/native"]
        # Set environment variable for PulseAudio server inside container
        run_args += ["-e", "PULSE_SERVER=unix:/run/pulse/native"]
        # Optionally, set the SDL audio driver to use PulseAudio
        run_args += ["-e", "SDL_AUDIODRIVER=pulse"]
    elif system == "Darwin":
        # macOS doesn't have /dev/snd, skip audio device mounting
        print("Note: Audio device passthrough is not supported on macOS")
    else:
        print(f"Warning: Unknown platform {system}, skipping audio configuration")

    # Set the working directory
    run_args += ["-w", "/workspaces/spot_choreo_utils"]

    # Mount the repository code into the workspace
    run_args += ["-v", f"{repo_root}:/workspaces/spot_choreo_utils"]

    # Set the image name
    run_args += [image_name]
    subprocess.run(run_args, check=True)


def remove_containers(container_name: str) -> None:
    """Stop any running containers with the container name"""
    docker_query_res = subprocess.run(
        ["docker", "ps", "-a", "--filter", f"name={container_name}", "--format", "{{.ID}}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True,
    )
    # Remove all container IDs that match the container name
    container_ids = docker_query_res.stdout.strip().split("\n")
    for id in container_ids:
        subprocess.run(["docker", "rm", "-f", id])


def join_container(container_name: str) -> None:
    """Shell into a running container"""
    subprocess.run(["docker", "exec", "-it", container_name, "bash"])
    pass


def check_for_container_running(container_name: str) -> bool:
    """Checks if a docker container is currently running with the container name"""

    query_res = subprocess.run(
        ["docker", "ps", "-a", "--filter", f"name={container_name}", "--filter", "status=running"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )

    if query_res.returncode != 0:
        return False

    return container_name in query_res.stdout.strip()


def main() -> None:
    """Build and start"""
    parser = ArgumentParser(description="Build the combined bdai/isaac image")
    parser.add_argument("--skip_build", help="Skip docker image build", action="store_true")
    parser.add_argument("--image_name", help="Set docker image name", default="spot_choreo_utils")
    parser.add_argument("--container_name", help="Set docker container name", default="spot_choreo_utils")
    parser.add_argument(
        "--restart_container",
        help="Set to force a container restart instead of joining any existing containers",
        action="store_true",
    )

    args = parser.parse_args()

    # Decide whether to join an existing conatiner or start a new one
    is_container_running = check_for_container_running(args.container_name)

    if is_container_running and args.restart_container:
        remove_containers(args.container_name)
        is_container_running = False

    if not is_container_running and not args.skip_build:
        build_image(args.image_name)

    if is_container_running:
        join_container(args.container_name)
    else:
        remove_containers(args.container_name)
        start_container(args.image_name, args.container_name)


if __name__ == "__main__":
    main()
