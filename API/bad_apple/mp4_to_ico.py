
import cv2
import os
import sys
from PIL import Image


def mp4_to_ico(video_path, output_folder="ico_frames", output_fps=1):
    if not os.path.isfile(video_path):
        print(f"Error: Video not found: {video_path}")
        return

    if output_fps <= 0:
        print("Error: output_fps must be greater than 0.")
        return

    os.makedirs(output_folder, exist_ok=True)

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        print("Error: Could not open video.")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    duration = total_frames / fps

    print(f"Video FPS: {fps}")
    print(f"Duration: {duration:.2f} seconds")
    print(f"Extracting frames at {output_fps} FPS...")

    interval = 1 / output_fps
    timestamp = 0
    frame_number = 0

    while timestamp < duration:
        cap.set(cv2.CAP_PROP_POS_MSEC, timestamp * 1000)

        ret, frame = cap.read()

        if not ret:
            break

        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(frame_rgb)
        image = image.resize((256, 256), Image.Resampling.LANCZOS)

        output_path = os.path.join(
            output_folder,
            f"frame_{frame_number:05d}.ico"
        )

        image.save(output_path, format="ICO")

        print(f"Saved: {output_path}")

        timestamp += interval
        frame_number += 1

    cap.release()

    print(f"\nDone! {frame_number} ICO images saved in: {output_folder}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python mp4_to_ico.py video.mp4 [output_fps]")
        sys.exit(1)

    video = sys.argv[1]
    output_fps = float(sys.argv[2]) if len(sys.argv) > 2 else 1

    mp4_to_ico(video, output_fps=output_fps)
