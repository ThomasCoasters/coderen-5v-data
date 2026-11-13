
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

    if fps <= 0:
        print("Error: Could not determine video FPS.")
        cap.release()
        return

    duration = total_frames / fps

    print(f"Video FPS: {fps}")
    print(f"Duration: {duration:.2f} seconds")
    print(f"Extracting frames at {output_fps} FPS...")

    frame_interval = fps / output_fps
    frame_index = 0
    output_index = 0
    next_frame = 0

    while True:
        ret, frame = cap.read()

        if not ret:
            break

        if frame_index >= round(next_frame):
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            image = Image.fromarray(frame_rgb)
            image = image.resize(
                (256, 256),
                Image.Resampling.LANCZOS
            )

            output_path = os.path.join(
                output_folder,
                f"frame_{output_index:05d}.ico"
            )

            image.save(output_path, format="ICO")

            print(f"Saved: {output_path}")

            output_index += 1
            next_frame = output_index * frame_interval

        frame_index += 1

    cap.release()

    print(f"\nDone! {output_index} ICO images saved in: {output_folder}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python mp4_to_ico.py video.mp4 [output_fps]")
        sys.exit(1)

    video = sys.argv[1]
    output_fps = float(sys.argv[2]) if len(sys.argv) > 2 else 1

    mp4_to_ico(video, output_fps=output_fps)
