# spot_choreo_utils
This repository enables programatically building, editing, and playing back choreography on Spot. It's built on top of the [Python Choreography Client](https://github.com/boston-dynamics/spot-sdk/tree/master/python/bosdyn-choreography-client/src/bosdyn/choreography/client) and allows programmers to directly interact with the [SDK and animations](https://dev.bostondynamics.com/docs/concepts/choreography/readme#) without requiring the Choreographer Graphical User Interface.

Users can:
- Programatically build animations and choreography sequences
- Build animations by posing the physical robot (using the spot tablet or other control interface) and save the robot's joint angles as a keyframe pose
- Build animations by posing a robot through a web interface and playing back on robot
- Play choreography sequences on multiple robots synchronized with music

See the tutorials folder for walk throughs on these topics.

### Repo Structure
- choreo_files: storage for example animations and choreography files, and default place that new animations are stored (gitignored)
- docker: contains dockerfiles and scripts to setup a basic environment for choreography development
- external: git submodule dependencies for the spot_chore_utils repo
- spot_choreo_utils: core library
    - test: Unit tests for the library
- tutorials: jupyter notebook tutorials of how to use spot_choreo_utils

# Installation
This repository uses git submodules and Docker to manage dependencies. The easiest way to start working with spot_choreo_utils is to:
  - git submodule init
  - git submodule update
  - cd docker
  - python start_docker.py

This will download all external dependency repositories, build a docker image and start a new container with all dependencies installed. The repository is passed into the docker image as a volume so that changes will automatically pass through and persist on disk.

The Docker image includes:
- Python 3.10 with pip
- ROS2 Humble
- Node.js 18.x and npm (for frontend development)
- Drake robotics library (x86_64 only)
- All Python dependencies from requirements.txt

For a full dependencies list see the Dockerfile and entrypoint scripts.

## macOS-Specific Setup
On macOS, Docker networking works differently than Linux. The script automatically:
- Detects unavailable ports and uses alternatives
- Maps container ports to host ports (instead of using --net=host)
- Skips audio device mounting (not available on macOS)

### Port Mappings
The following services are exposed with automatic port conflict resolution:
- Jupyter Notebook: http://localhost:8888 (or alternative if in use)
- Web Animator: http://localhost:7000 (may use 17000 if 7000 is occupied)
- Frontend Dev Server: http://localhost:3000
- FastAPI Backend: http://localhost:8000

### Starting Jupyter Notebook on macOS
After entering the Docker container, manually start Jupyter:
```bash
# Inside the container
cd /workspaces/spot_choreo_utils
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```
Then access Jupyter at the URL shown in the terminal output.

### Known macOS Limitations
- Audio passthrough is not supported on macOS Docker
- ARM64 builds take significantly longer due to building Drake from source (30-60 minutes)

### Drake Installation Notes
- **x86_64 (Intel Macs)**: Uses pre-built Drake v1.24.0 binary (installed during Docker build)
- **ARM64 (Apple Silicon)**: Builds Drake v1.24.0 from source on first container start (30-60 minutes)
- Both architectures result in fully functional Drake installations
- ARM64 builds include progress monitoring: `docker exec -it spot_choreo_utils tail -f /tmp/drake_build.log`
- Check Drake status anytime: `./check_drake_build.sh` (inside container)

## Setting up the Web Animator
The Web Animator provides a way to create pose-to-pose animations through the web browser.
  - cd spot_choreo_utils/web_animator
  - pip install -e .


## Animating with the Web Animator
You can explore potential choreographic poses and export them for testing on the robot through the Web Animator. The Web Animator does its best to guarantee stability and on robot validity when all feet are locked on the ground, but once feet are unlocked there is a much heavier burden placed on the choreographer to think about stability and comply with choreographer protobuf requirements.

To start animating:
1. Start the backend server:
   ```bash
   cd spot_choreo_utils/web_animator/spot_web_animator
   python animate.py
   # Type an animation name when prompted
   ```

2. Start the frontend (in a separate terminal):
   ```bash
   cd spot_choreo_utils/frontend
   npm install  # First time only
   npm start
   ```

3. Access the web interface:
   - Frontend: http://localhost:3000 (or the port shown in Docker output)
   - Backend visualizer: http://localhost:7000 (or alternative port if 7000 is in use)

Use the animation sliders to set robot poses, and then use the Save Pose As Keyframe button to add the pose to an animation. The animation you create will be saved to the active directory under choreo_files.

### Frontend Development
The frontend is a React application that provides the web interface for the animator.

#### Available Scripts
- `npm start` - Runs the development server
- `npm build` - Creates a production build
- `npm test` - Runs the test suite

#### Node.js 18 Compatibility Note
The frontend uses react-scripts v3.0.1 which has compatibility issues with Node.js 18's OpenSSL 3.0. The package.json has been configured to use the legacy OpenSSL provider (`NODE_OPTIONS=--openssl-legacy-provider`) as a workaround.

# Contributing to this repo
This repository enforces `ruff` and `black` linting. To verify that your code will pass inspection, install `pre-commit` and run:
```bash
pre-commit install
pre-commit run --all-files
```
The [Google Style Guide](https://google.github.io/styleguide/) is followed for default formatting. 

### Testing 
The spot_choreo_utils library uses pytest for unit testing. Prior to submitting code please add unit tests and verify that all tests pass with pytest
- start the docker
- pytest

### Generating Protos
If you change the proto definitions, re-generate the pb2.py definitions with: 
- cd spot_choreo_utils/spot_choreo_utils/protos
- python regenerate_protos.py

## Troubleshooting

### Common macOS Issues

#### Port Already in Use
If you see "bind: address already in use" errors:
- The script automatically finds alternative ports
- Check the console output for the actual ports being used
- Common conflicts: Port 7000 (used by Control Center on macOS)

#### Drake Build Issues on ARM64
- **First Startup Delay**: Drake builds from source on Apple Silicon during first container start (30-60 minutes)
- **Build Monitoring**: Monitor progress with `docker exec -it spot_choreo_utils tail -f /tmp/drake_build.log`
- **Build Failures**: Ensure Docker has sufficient resources (8GB+ RAM, 20GB+ disk space)
- **Build Timeout**: Builds timeout after 90 minutes - restart container to retry if needed

#### Container Won't Start Interactively
If you get "the input device is not a TTY" errors:
- Make sure you're running the command in a real terminal (not through scripts)
- Try: `docker exec -it spot_choreo_utils bash` after the container is running

#### Jupyter Notebook Not Accessible
- Ensure you start Jupyter with `--ip=0.0.0.0` flag
- Check that the port mapping is correct in `docker ps`
- Try accessing via the token URL shown in Jupyter output

#### Frontend npm start OpenSSL Error
If you see "Error: error:0308010C:digital envelope routines::unsupported":
- This is due to react-scripts v3.0.1 incompatibility with Node.js 18
- The package.json has been updated with NODE_OPTIONS=--openssl-legacy-provider
- Run `npm start` normally - the workaround is already applied
