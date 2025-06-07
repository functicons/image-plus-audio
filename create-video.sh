#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Script to create a video using the Docker container

# Default image name
DOCKER_IMAGE_NAME="image-plus-audio:latest"

# --- Helper function to display usage ---
usage() {
  echo "Usage: $0 <path_to_image_file> <path_to_audio_file> <path_to_output_video_file> [--fps <frames_per_second>]"
  echo ""
  echo "Arguments:"
  echo "  <path_to_image_file>      : Path to the input image (e.g., sample_files/my_image.jpg)"
  echo "  <path_to_audio_file>      : Path to the input audio (e.g., sample_files/my_audio.mp4 or sample_files/my_audio.mp3)"
  echo "  <path_to_output_video_file>: Path for the generated video (e.g., output/my_video.mp4)"
  echo ""
  echo "Optional arguments:"
  echo "  --fps <frames>            : Frames per second for the output video (default: 24)"
  echo ""
  echo "Example:"
  echo "  $0 ./sample_files/image.png ./sample_files/audio.mp3 ./output_files/result.mp4"
  echo "  $0 ./sample_files/photo.jpg ./sample_files/sound.mp4 ./output_files/final_video.mp4 --fps 30"
  exit 1
}

# --- Check for minimum number of arguments ---
if [ "$#" -lt 3 ]; then
  echo "❌ Error: Missing required arguments."
  usage
fi

HOST_IMAGE_PATH="$1"
HOST_AUDIO_PATH="$2"
HOST_OUTPUT_VIDEO_PATH="$3"
shift 3 # Remove the first three arguments

FPS_VALUE="24" # Default FPS

# Parse optional --fps argument
while (( "$#" )); do
  case "$1" in
    --fps)
      if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -gt 0 ]; then
        FPS_VALUE="$2"
        shift 2
      else
        echo "Error: --fps requires a positive numeric argument." >&2
        usage
      fi
      ;;
    *) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      usage
      ;;
  esac
done


# --- Validate input files exist ---
if [ ! -f "$HOST_IMAGE_PATH" ]; then
  echo "❌ Error: Image file not found at '$HOST_IMAGE_PATH'"
  exit 1
fi

if [ ! -f "$HOST_AUDIO_PATH" ]; then
  echo "❌ Error: Audio file not found at '$HOST_AUDIO_PATH'"
  exit 1
fi

# --- Prepare paths for Docker volumes ---
# We need absolute paths for Docker volume mounts for robustness
# For macOS, `realpath` might not be available by default. `cd && pwd` is more portable.
ABS_HOST_IMAGE_PATH="$(cd "$(dirname "$HOST_IMAGE_PATH")" && pwd)/$(basename "$HOST_IMAGE_PATH")"
ABS_HOST_AUDIO_PATH="$(cd "$(dirname "$HOST_AUDIO_PATH")" && pwd)/$(basename "$HOST_AUDIO_PATH")"

# Create output directory if it doesn't exist and get its absolute path
mkdir -p "$(dirname "$HOST_OUTPUT_VIDEO_PATH")"
ABS_HOST_OUTPUT_DIR="$(cd "$(dirname "$HOST_OUTPUT_VIDEO_PATH")" && pwd)"
OUTPUT_VIDEO_FILENAME="$(basename "$HOST_OUTPUT_VIDEO_PATH")"

if [ ! -d "$ABS_HOST_OUTPUT_DIR" ]; then
    echo "❌ Error: Could not create or access output directory '$ABS_HOST_OUTPUT_DIR'."
    exit 1
fi

# --- Define container mount points and file paths ---
# Parent directory of the image file on the host
HOST_IMAGE_PARENT_DIR=$(dirname "$ABS_HOST_IMAGE_PATH")
# Parent directory of the audio file on the host
HOST_AUDIO_PARENT_DIR=$(dirname "$ABS_HOST_AUDIO_PATH")

# Mount points inside the container
CONTAINER_IMG_SRC_MOUNT="/mnt/img_src"
CONTAINER_AUDIO_SRC_MOUNT="/mnt/audio_src"
CONTAINER_OUTPUT_MOUNT="/mnt/output"

# Full paths to files inside the container
CONTAINER_IMAGE_PATH="${CONTAINER_IMG_SRC_MOUNT}/$(basename "$ABS_HOST_IMAGE_PATH")"
CONTAINER_AUDIO_PATH="${CONTAINER_AUDIO_SRC_MOUNT}/$(basename "$ABS_HOST_AUDIO_PATH")"
CONTAINER_OUTPUT_VIDEO_PATH="${CONTAINER_OUTPUT_MOUNT}/${OUTPUT_VIDEO_FILENAME}"

echo "🎬 Processing video with the following parameters:"
echo "  Host Image Path: $ABS_HOST_IMAGE_PATH"
echo "  Host Audio Path: $ABS_HOST_AUDIO_PATH"
echo "  Host Output Dir: $ABS_HOST_OUTPUT_DIR"
echo "  Output Filename: $OUTPUT_VIDEO_FILENAME"
echo "  FPS: $FPS_VALUE"
echo ""
echo "  Container Mounts:"
echo "    Image Dir: ${HOST_IMAGE_PARENT_DIR} -> ${CONTAINER_IMG_SRC_MOUNT}"
echo "    Audio Dir: ${HOST_AUDIO_PARENT_DIR} -> ${CONTAINER_AUDIO_SRC_MOUNT}"
echo "    Output Dir: ${ABS_HOST_OUTPUT_DIR} -> ${CONTAINER_OUTPUT_MOUNT}"
echo ""
echo "  Container File Paths:"
echo "    Image: ${CONTAINER_IMAGE_PATH}"
echo "    Audio: ${CONTAINER_AUDIO_PATH}"
echo "    Output: ${CONTAINER_OUTPUT_VIDEO_PATH}"
echo ""

echo "🚀 Running Docker container ${DOCKER_IMAGE_NAME}..."

# We use --user "$(id -u):$(id -g)" to ensure output files are owned by the host user.
# :ro for read-only input mounts, :rw for read-write output mount.
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "${HOST_IMAGE_PARENT_DIR}:${CONTAINER_IMG_SRC_MOUNT}:ro" \
  -v "${HOST_AUDIO_PARENT_DIR}:${CONTAINER_AUDIO_SRC_MOUNT}:ro" \
  -v "${ABS_HOST_OUTPUT_DIR}:${CONTAINER_OUTPUT_MOUNT}:rw" \
  "${DOCKER_IMAGE_NAME}" \
  "${CONTAINER_IMAGE_PATH}" \
  "${CONTAINER_AUDIO_PATH}" \
  "${CONTAINER_OUTPUT_VIDEO_PATH}" \
  --fps "${FPS_VALUE}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  FULL_OUTPUT_PATH="${ABS_HOST_OUTPUT_DIR}/${OUTPUT_VIDEO_FILENAME}"
  if [ -f "$FULL_OUTPUT_PATH" ]; then
    echo "🎉 Video file successfully created: '$FULL_OUTPUT_PATH'"
  else
    echo "⚠️ Warning: Docker container finished successfully, but the output video file was NOT found at '$FULL_OUTPUT_PATH'."
    echo "   This might indicate an issue within the Python script (e.g., moviepy error not caught) or a permissions problem despite user mapping."
    echo "   Please check the script logs above for any errors from moviepy or ffmpeg."
    exit 1 # Signal failure if output not found
  fi
else
  echo "❌ Docker container run failed with exit code ${EXIT_CODE}."
  echo "   Make sure Docker is running and the image '${DOCKER_IMAGE_NAME}' is built correctly."
  echo "   Review logs above for errors from the container or Python script."
  exit $EXIT_CODE
fi
