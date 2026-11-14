
import av
import json
import numpy as np

from numba import njit
from pathlib import Path


# CONFIGURATION

VIDEO_PATH = r"C:\Users\thoma\Documents\coding\coderen-5v-data\API\bad_apple\assets\badapple.mp4"

OUTPUT_FILE = r"C:\Users\thoma\Documents\coding\coderen-5v-data\API\bad_apple\badapple_rectangles.json"

TARGET_FPS = 30
WINDOW_COUNT = 50
WHITE_THRESHOLD = 127


# COMPILED RECTANGLE ALGORITHM

@njit(cache=True)
def extract_rectangles(image, target_count, threshold):

    height, width = image.shape

    grid = (image > threshold).astype(np.uint8)

    remaining = int(grid.sum())

    results = np.zeros((target_count, 4), dtype=np.int32)

    if remaining == 0:
        return results, 0

    heights = np.zeros(width, dtype=np.int32)
    stack = np.empty(width, dtype=np.int32)

    result_count = 0

    for iteration in range(target_count):

        if remaining == 0:
            break

        heights[:] = 0

        best_area = 0
        best_x = 0
        best_y = 0
        best_w = 0
        best_h = 0

        for y in range(height):

            # Update histogram.
            for x in range(width):
                if grid[y, x] != 0:
                    heights[x] += 1
                else:
                    heights[x] = 0

            # Find largest histogram rectangle.
            stack_size = 0

            for x in range(width + 1):

                current_height = 0

                if x < width:
                    current_height = heights[x]

                while stack_size > 0:

                    top = stack[stack_size - 1]
                    top_height = heights[top]

                    if current_height >= top_height:
                        break

                    stack_size -= 1

                    left = 0

                    if stack_size > 0:
                        left = stack[stack_size - 1] + 1

                    rect_width = x - left
                    area = top_height * rect_width

                    if area > best_area:
                        best_area = area
                        best_x = left
                        best_y = y - top_height + 1
                        best_w = rect_width
                        best_h = top_height

                if x < width:
                    stack[stack_size] = x
                    stack_size += 1

        if best_area == 0:
            break

        results[result_count, 0] = best_x
        results[result_count, 1] = best_y
        results[result_count, 2] = best_w
        results[result_count, 3] = best_h

        result_count += 1

        # Remove selected rectangle.
        for y in range(best_y, best_y + best_h):
            for x in range(best_x, best_x + best_w):
                if grid[y, x] != 0:
                    grid[y, x] = 0
                    remaining -= 1

    return results, result_count


# VIDEO PROCESSING

def main():

    output_path = Path(OUTPUT_FILE)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print("Opening video...")

    container = av.open(VIDEO_PATH)
    stream = container.streams.video[0]

    width = stream.codec_context.width
    height = stream.codec_context.height

    duration = float(stream.duration * stream.time_base)

    print(f"Resolution: {width}x{height}")
    print(f"Duration: {duration:.3f}s")
    print(f"Target FPS: {TARGET_FPS}")
    print(f"Target frames: {int(np.ceil(duration * TARGET_FPS))}")
    print(f"Windows: {WINDOW_COUNT}")

    # Compile Numba before processing.
    print("\nCompiling rectangle algorithm (first run only)...")

    dummy = np.zeros((height, width), dtype=np.uint8)

    extract_rectangles(
        dummy,
        WINDOW_COUNT,
        WHITE_THRESHOLD
    )

    print("Compilation complete.")
    print("\nProcessing video...")

    next_timestamp = 0.0
    frame_interval = 1.0 / TARGET_FPS

    processed = 0

    with open(output_path, "w", encoding="utf-8") as output:

        output.write('{"frames":[')

        first = True

        for frame in container.decode(stream):

            if frame.pts is None:
                continue

            timestamp = float(frame.pts * frame.time_base)

            # Convert frame to native-resolution grayscale.
            gray = frame.to_ndarray(format="gray")

            # Timestamp-based sampling.
            while next_timestamp < duration and next_timestamp <= timestamp + 0.000001:

                rects, count = extract_rectangles(
                    gray,
                    WINDOW_COUNT,
                    WHITE_THRESHOLD
                )

                # Only export "r".
                frame_data = {
                    "r": rects[:count].tolist()
                }

                if not first:
                    output.write(",")

                json.dump(
                    frame_data,
                    output,
                    separators=(",", ":")
                )

                first = False

                processed += 1
                next_timestamp += frame_interval

                if processed % 30 == 0:
                    print(
                        f"Processed: {processed} frames | "
                        f"{processed / TARGET_FPS:.1f}s | "
                        f"{processed / (duration * TARGET_FPS) * 100:.1f}%"
                    )

        output.write("]}")

    container.close()

    print("\nFinished!")
    print(f"Frames generated: {processed}")
    print(f"Output: {output_path}")


if __name__ == "__main__":
    main()
