# Use an official Python 3.12 runtime as a parent image
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies required by MoviePy (especially ffmpeg)
# Also install procps for `ps` command if needed for debugging, though not strictly necessary for moviepy
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip, setuptools, and wheel
RUN python -m pip install --upgrade pip wheel setuptools

# Copy the requirements file first to leverage Docker cache
COPY src/requirements.txt /app/

# Install Python dependencies
RUN echo "Forcing re-run of pip install to ensure correct moviepy installation..." && \
    pip install --no-cache-dir -r requirements.txt

# Copy the content of the local src directory to the working directory
COPY src/ /app/

# Make the script executable (good practice, though python interpreter will run it)
RUN chmod +x /app/create_video.py

# Define environment variable (optional)
ENV APP_NAME ImageToVideoConverter

# Set the entrypoint to the python script
ENTRYPOINT ["python", "/app/create_video.py"]