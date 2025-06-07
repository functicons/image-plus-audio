#!/usr/bin/env python3
import argparse
import os
from moviepy import ImageClip, AudioFileClip # Standard import
import traceback # Added for more detailed error printing if needed

def make_video(image_path, audio_path, output_path, fps=24):
    """
    Creates a video from an image and an audio file.
    The image will be displayed for the duration of the audio.
    """
    audio_clip = None # Initialize to allow cleanup in finally
    image_clip = None
    final_clip = None
    try:
        print(f"🎬 Starting video creation...")
        print(f"🖼️ Image: {image_path}")
        print(f"🎵 Audio: {audio_path}")
        print(f"🎞️ Output: {output_path}")
        print(f"⏱️ FPS: {fps}")

        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        # Load the audio clip to get its duration
        print("⏳ Loading audio...")
        audio_clip = AudioFileClip(audio_path)
        duration = audio_clip.duration

        if duration is None or duration <= 0:
            raise ValueError("Audio duration is invalid or zero. Ensure the input audio file has a valid audio track and is not silent/empty.")

        print(f"Audio duration: {duration:.2f} seconds")

        # Create an image clip and set its duration
        print("🖼️ Processing image...")
        image_clip = ImageClip(image_path, duration=duration)

        # Set the audio of the image clip
        print("➕ Combining image and audio...")
        final_clip = image_clip.with_audio(audio_clip)

        # Determine a writable path for the temporary audio file
        output_dir = os.path.dirname(output_path)
        # MoviePy should clean up this temp file if a string path is given.
        # Using a fixed name is simpler than generating unique names here.
        temp_audiofile_path = os.path.join(output_dir, "temp_processing_audio.mp4")
        print(f"🛠️  Using temporary audio file location: {temp_audiofile_path}")

        # Write the result to a file
        print(f"💾 Writing video to {output_path}...")
        final_clip.write_videofile(
            output_path,
            fps=fps,
            codec="libx264",
            audio_codec="aac",
            logger='bar',
            temp_audiofile=temp_audiofile_path # Explicitly set temp audio file path
        )

        print(f"✅ Video '{output_path}' created successfully!")

    except Exception as e:
        print(f"❌ Error creating video: {e}")
        traceback.print_exc() # Print full traceback for detailed debugging
        # Re-raise the exception to signal failure to the calling script/Docker
        raise
    finally:
        # Ensure clips are closed to free resources, checking if they were defined
        if audio_clip:
            audio_clip.close()
        if image_clip:
            image_clip.close()
        if final_clip: # final_clip might be the same as image_clip if set_audio returns self
            final_clip.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a video from an image and an audio file.")
    parser.add_argument("image_path", help="Path to the input image file (e.g., .png, .jpg)")
    parser.add_argument("audio_path", help="Path to the input audio file (e.g., .mp4 containing audio, .mp3, .wav)")
    parser.add_argument("output_path", help="Path to the output video file (e.g., .mp4)")
    parser.add_argument("--fps", type=int, default=24, help="Frames per second for the output video (default: 24)")

    args = parser.parse_args()

    make_video(args.image_path, args.audio_path, args.output_path, args.fps)