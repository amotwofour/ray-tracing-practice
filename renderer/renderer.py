from __future__ import annotations

import argparse
import tkinter as tk
from pathlib import Path

try:
    from PIL import Image, ImageTk  # type: ignore[import-not-found]
except ImportError as exc:
    raise SystemExit(
        "Pillow is required for live rendering. Install it with: pip install pillow"
    ) from exc


def parse_partial_p3_ppm(ppm_path: Path) -> tuple[Image.Image, int, int] | None:
    try:
        raw_text = ppm_path.read_text(encoding="ascii", errors="ignore")
    except FileNotFoundError:
        return None

    tokens: list[str] = []
    for line in raw_text.splitlines():
        if "#" in line:
            line = line.split("#", 1)[0]
        tokens.extend(line.split())

    if len(tokens) < 4 or tokens[0] != "P3":
        return None

    try:
        width = int(tokens[1])
        height = int(tokens[2])
        max_value = int(tokens[3])
    except ValueError:
        return None

    if width <= 0 or height <= 0 or max_value <= 0:
        return None

    expected_channels = width * height * 3
    channel_tokens = tokens[4 : 4 + expected_channels]

    channels = bytearray(expected_channels)
    valid_channels = 0
    scale = 255.0 / max_value

    for i, token in enumerate(channel_tokens):
        try:
            value = int(token)
        except ValueError:
            break

        if value < 0:
            value = 0
        elif value > max_value:
            value = max_value

        channels[i] = int(value * scale)
        valid_channels += 1

    completed_rows = valid_channels // (width * 3)
    image = Image.frombytes("RGB", (width, height), bytes(channels))
    return image, completed_rows, height


class LivePPMViewer:
    def __init__(self, ppm_path: Path, refresh_ms: int = 100) -> None:
        self.ppm_path = ppm_path
        self.refresh_ms = refresh_ms

        self.root = tk.Tk()
        self.root.title(f"Live PPM Renderer - {ppm_path}")

        self.image_label = tk.Label(self.root, text="Waiting for image data...")
        self.image_label.pack()

        self.status_label = tk.Label(self.root, text="")
        self.status_label.pack()

        self._photo: ImageTk.PhotoImage | None = None
        self._last_size = -1
        self._last_mtime_ns = -1

    def _file_changed(self) -> bool:
        try:
            stat = self.ppm_path.stat()
        except FileNotFoundError:
            return False

        if stat.st_size != self._last_size or stat.st_mtime_ns != self._last_mtime_ns:
            self._last_size = stat.st_size
            self._last_mtime_ns = stat.st_mtime_ns
            return True
        return False

    def _update_frame(self) -> None:
        if not self.ppm_path.exists():
            self.status_label.config(text=f"Waiting for {self.ppm_path}...")
            self.root.after(self.refresh_ms, self._update_frame)
            return

        if not self._file_changed():
            self.root.after(self.refresh_ms, self._update_frame)
            return

        parsed = parse_partial_p3_ppm(self.ppm_path)
        if parsed is None:
            self.status_label.config(text="File exists, but header/data is not ready yet.")
            self.root.after(self.refresh_ms, self._update_frame)
            return

        image, completed_rows, total_rows = parsed
        self._photo = ImageTk.PhotoImage(image)
        self.image_label.config(image=self._photo, text="")
        self.status_label.config(
            text=(
                f"Rendering progress: {completed_rows}/{total_rows} scanlines "
                f"({(completed_rows / total_rows) * 100:.1f}%)"
            )
        )
        self.root.after(self.refresh_ms, self._update_frame)

    def run(self) -> None:
        self._update_frame()
        self.root.mainloop()


def parse_args() -> argparse.Namespace:
    default_ppm = Path(__file__).resolve().parents[1] / "cpu-version" / "image.ppm"

    parser = argparse.ArgumentParser(
        description="Live viewer for P3 PPM files that are still being rendered."
    )
    parser.add_argument(
        "--file",
        type=Path,
        default=default_ppm,
        help="Path to the PPM file (default: ../cpu-version/image.ppm)",
    )
    parser.add_argument(
        "--interval-ms",
        type=int,
        default=100,
        help="Refresh interval in milliseconds (default: 100)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    viewer = LivePPMViewer(ppm_path=args.file, refresh_ms=max(25, args.interval_ms))
    viewer.run()


if __name__ == "__main__":
    main()