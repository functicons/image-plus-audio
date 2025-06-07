# Image + Audio = Video 🖼️+🎶=🎬

This project provides a Python script packaged in a Docker container to create a video file from a single image and an audio file. The image will be displayed for the duration of the audio.

## Features ✨

* Combines a static image (PNG, JPG, etc.) with an audio track (MP3, MP4 audio, WAV, etc.) into a video (MP4).
* Packaged as a Docker image for easy and consistent execution across different environments.
* Shell scripts provided for building the Docker image and running the video creation process.
* Customizable FPS (Frames Per Second) for the output video.
* Output video uses H.264 video codec (`libx264`) and AAC audio codec (`aac`) for broad compatibility.

## Prerequisites 🛠️

* **Docker**: Ensure Docker is installed and running on your system.
* **Bash Shell**: For running the helper scripts (typically available on Linux and macOS. For Windows, use WSL, Git Bash, or a similar environment).

## Project Structure 📂

image_plus_audio/
├── src/
│   ├── create_video.py      # Python script for video creation
│   └── requirements.txt     # Python dependencies
├── Dockerfile               # Docker image definition
├── build-docker-image.sh          # Script to build the Docker image
├── create-video.sh   # Script to run the video creation
├── README.md                # This readme file
└── sample_files/            # Directory for your sample input files (you'll need to create this or use your own paths)
├── image.png            # (Example: place your image here)
└── audio.mp3            # (Example: place your audio here - .mp3, .wav, .m4a, or .mp4 with audio track)

## Setup 🚀

1.  **Download or Clone:**
    Obtain the project files (e.g., by cloning the repository or downloading and extracting a ZIP). If you're reading this, you might have just run `generate_project.sh` which does this for you!

2.  **Navigate to Project Directory:**
    Open your terminal and change to the project's root directory:
    ```bash
    cd image_video_creator
    ```

3.  **Make Scripts Executable:**
    (The `generate_project.sh` script should have already done this. If not, or if you downloaded manually:)
    ```bash
    chmod +x build-docker-image.sh
    chmod +x create-video.sh
    chmod +x src/create_video.py
    ```

4.  **Build the Docker Image:**
    Run the build script:
    ```bash
    ./build-docker-image.sh
    ```
    This will create a Docker image named `image-to-video-converter:latest`. You only need to do this once, or when you change the `Dockerfile` or Python script.

## Usage 🎬

1.  **Prepare Your Input Files:**
    * Have an image file (e.g., `my_image.png`, `photo.jpg`).
    * Have an audio file (e.g., `my_audio.mp3`, `soundtrack.mp4` which contains an audio track).
    * You can use the `sample_files` directory in the project root (you'll need to put your files there) or use any other paths.

2.  **Run the Video Creation Script:**
    Execute the `create-video.sh` script, providing the paths to your image, audio, and the desired output video file.
    ```bash
    ./create-video.sh <path_to_your_image> <path_to_your_audio> <path_for_your_output_video.mp4> [--fps <frames>]
    ```

    **Examples:**

    * Assuming you have `sample_files/image.png` and `sample_files/audio.mp3` (after placing them there):
        ```bash
        # Create an output directory if it doesn't exist (optional, script handles it too)
        mkdir -p output_videos

        ./create-video.sh ./sample_files/image.png ./sample_files/audio.mp3 ./output_videos/my_final_video.mp4
        ```

    * To specify FPS (e.g., 30 FPS) and use files from different locations:
        ```bash
        ./create-video.sh ~/Pictures/my_holiday.jpg /path/to/my_music/song.mp4 ./my_project_video.mp4 --fps 30
        ```
    * If your filenames or paths contain spaces, remember to quote them:
        ```bash
        ./create-video.sh "./sample_files/my awesome image.png" "./sample_files/cool song.mp3" "./output_videos/final cut.mp4"
        ```

3.  **Find Your Video:**
    The generated video will be saved to the output path you specified. The script uses Docker volume mounts to read your input files and write the output file directly to your host filesystem. Thanks to the `--user "$(id -u):$(id -g)"` flag in the `docker run` command, the output file should have the same ownership as the user running the script (on Linux/macOS).

## Python Script Details (`src/create_video.py`) 🐍

The core logic resides in `src/create_video.py` and uses the `moviepy` library.
* It takes an image path, audio path, output path, and an optional FPS as command-line arguments.
* The image is displayed for the full duration of the audio track.
* It includes basic file existence checks and validation for audio duration.
* Uses `libx264` video codec and `aac` audio codec for creating MP4 files, ensuring good quality and compatibility.

## Dockerization Details 🐳

* **Base Image**: `python:3.9-slim` (a lightweight official Python image).
* **Key Dependencies**: `ffmpeg` (system-level utility for video/audio processing), `moviepy` (Python library).
* **Entrypoint**: The container is configured to directly run the `create_video.py` script, passing along arguments provided to `docker run`.
* **Volume Mounts**: The `create-video.sh` script intelligently mounts the parent directories of your input files (read-only) and the target output directory (read-write) into the container. This allows the script inside Docker to access your files seamlessly.

## Troubleshooting ⚠️

* **`docker` command not found / permission denied**: Ensure Docker is installed, the Docker daemon is running, and your user has permissions to interact with it. On Linux, you might need to add your user to the `docker` group (e.g., `sudo usermod -aG docker $USER` and then log out/in) or run Docker commands with `sudo` (less recommended for general use).
* **Script execution permission denied**: Make sure the shell scripts (`.sh`) are executable (`chmod +x script_name.sh`). The `generate_project.sh` should handle this for the main scripts.
* **"File not found" errors from `create-video.sh`**: Double-check the paths you provide as arguments. Relative paths are resolved from the directory where you run the script. Use absolute paths if unsure.
* **Video creation fails (MoviePy/ffmpeg errors in container logs)**:
    * The Docker build should install `ffmpeg`. If it failed, rebuild the image.
    * Check the console output when running `create-video.sh` for specific error messages from `moviepy` or `ffmpeg`.
    * The input audio/image file might be corrupted or in a very unusual format not fully supported by `ffmpeg` (though it's quite versatile).
    * Ensure the audio file actually contains an audio track with a positive duration. The Python script attempts to check for zero-duration audio.
* **Output video file not created or owned by root**: The `create-video.sh` script uses `--user "$(id -u):$(id -g)"` to mitigate permission issues for the output file on Linux/macOS. If you still face issues, check directory permissions on your host system for the output location.

Enjoy creating your videos! 😄
