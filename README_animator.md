# Spot Web Animator Quick Start

This guide provides the minimum steps to run the Spot Web Animator.

## Animation Files

Animations created with this tool are saved in: `choreo_files/active/`

## Prerequisites

- Docker installed on your system
- Two terminal windows

## Steps to Run

### 1. Start Docker Container

In your first terminal:
```bash
cd spot_choreo_utils/docker
python start_docker.py
```

### 2. Open Second Terminal

Open a new terminal window and shell into the Docker container:
```bash
docker exec -it spot_choreo_utils bash
```

### 3. Set PyDrake Path (Both Terminals)

In **both** terminals after shelling into Docker, run:
```bash
export PYTHONPATH="/opt/drake/lib/python3.10/site-packages:$PYTHONPATH"
export LD_LIBRARY_PATH="/opt/drake/lib:$LD_LIBRARY_PATH"
```

### 4. Start Frontend (Terminal 1)

In the first terminal (inside Docker):
```bash
cd /workspaces/spot_choreo_utils/spot_choreo_utils/frontend
npm start
```

The frontend will start on port 3000.

### 5. Start Backend (Terminal 2)

In the second terminal (inside Docker):
```bash
cd /workspaces/spot_choreo_utils/spot_choreo_utils/web_animato/spot_web_animator
python animate.py
```

The backend will start on port 8000 with MeshCat visualization on port 17000.

## Access the Application

- **Web Interface**: http://localhost:3000
- **MeshCat Visualizer**: http://localhost:17000

## Troubleshooting

If you encounter import errors:
- Ensure the Docker container has been built recently
- Check that PyDrake is accessible by running `python -c "import pydrake"`

## Stopping the Application

1. Press `Ctrl+C` in both terminals to stop the frontend and backend
2. Exit the Docker container with `exit`
3. Stop the Docker container if needed