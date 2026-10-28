#!/usr/bin/env python3
"""Technical validation for a locally rendered film.

Technical failures change the exit code. Calm motion, holds, and other
creative observations are notes. They do not fail the file.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, capture_output=True, text=True)


def probe(path: Path) -> dict:
    result = run([
        "ffprobe", "-v", "error", "-count_frames", "-show_streams",
        "-show_format", "-of", "json", str(path),
    ])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "ffprobe failed")
    return json.loads(result.stdout)


def check(technical: list[dict], name: str, ok: bool, detail: str) -> None:
    technical.append({"name": name, "ok": bool(ok), "detail": detail})


def note(notes: list[dict], name: str, detail: str) -> None:
    notes.append({"name": name, "detail": detail})


def stream_of(data: dict, kind: str) -> dict | None:
    for stream in data.get("streams", []):
        if stream.get("codec_type") == kind:
            return stream
    return None


def as_float(value: str | None) -> float | None:
    if not value:
        return None
    try:
        return float(value)
    except ValueError:
        return None


def black_frames(path: Path) -> int:
    result = run([
        "ffmpeg", "-v", "info", "-i", str(path),
        "-vf", "blackframe=amount=98:threshold=32", "-f", "null", "-",
    ])
    text = (result.stderr or "") + (result.stdout or "")
    return sum(1 for line in text.splitlines() if "blackframe:" in line)


def white_frames(path: Path) -> int:
    result = run([
        "ffmpeg", "-v", "info", "-i", str(path),
        "-vf", "negate,blackframe=amount=98:threshold=32", "-f", "null", "-",
    ])
    text = (result.stderr or "") + (result.stdout or "")
    return sum(1 for line in text.splitlines() if "blackframe:" in line)


def freeze_notes(path: Path) -> str:
    result = run([
        "ffmpeg", "-v", "info", "-i", str(path),
        "-vf", "freezedetect=n=-60dB:d=0.45", "-f", "null", "-",
    ])
    lines = [
        line.strip() for line in (result.stderr or "").splitlines()
        if "freeze_" in line
    ]
    return "; ".join(lines[:6]) if lines else "none"


def bar_note(path: Path, width: int, height: int) -> str | None:
    result = run([
        "ffmpeg", "-v", "error", "-i", str(path),
        "-vf", "cropdetect=limit=24:round=2:reset=0", "-f", "null", "-",
    ])
    crops = [
        line for line in (result.stderr or "").splitlines()
        if "crop=" in line
    ]
    if not crops:
        return None
    last = crops[-1]
    marker = "crop="
    value = last.split(marker, 1)[1].split(" ", 1)[0]
    parts = value.split(":")
    if len(parts) < 2:
        return None
    try:
        crop_w = int(parts[0])
        crop_h = int(parts[1])
    except ValueError:
        return None
    if crop_w < width * 0.9 or crop_h < height * 0.9:
        return f"cropdetect suggests {crop_w}x{crop_h} inside {width}x{height}"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a rendered film file.")
    parser.add_argument("--video", required=True)
    parser.add_argument("--expect-width", type=int, required=True)
    parser.add_argument("--expect-height", type=int, required=True)
    parser.add_argument("--expect-fps", type=float, required=True)
    parser.add_argument("--expect-frames", type=int, required=True)
    parser.add_argument("--expect-audio", choices=("no", "yes"), default="no")
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    path = Path(args.video)
    technical: list[dict] = []
    notes: list[dict] = []
    if not path.is_file() or path.stat().st_size <= 0:
        check(technical, "file", False, "missing or empty")
        report = {"technical_ok": False, "technical": technical, "creative_notes": notes}
        Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print("TECHNICAL FAIL  file: missing or empty")
        return 1

    try:
        data = probe(path)
    except (RuntimeError, json.JSONDecodeError) as error:
        check(technical, "decode probe", False, str(error))
        report = {"technical_ok": False, "technical": technical, "creative_notes": notes}
        Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"TECHNICAL FAIL  probe: {error}")
        return 1

    video = stream_of(data, "video")
    audio = stream_of(data, "audio")
    if video is None:
        check(technical, "video stream", False, "missing")
        video = {}
    else:
        check(technical, "video stream", True, video.get("codec_name", ""))

    width = int(video.get("width") or 0)
    height = int(video.get("height") or 0)
    check(technical, "dimensions", width == args.expect_width and height == args.expect_height,
          f"{width}x{height} (expected {args.expect_width}x{args.expect_height})")
    check(technical, "codec", video.get("codec_name") == "h264", video.get("codec_name") or "missing")
    check(technical, "pixel format", video.get("pix_fmt") == "yuv420p", video.get("pix_fmt") or "missing")

    rate = as_float(video.get("avg_frame_rate", "0/1").split("/")[0]) if "/" not in str(video.get("avg_frame_rate", "")) else None
    raw_rate = str(video.get("avg_frame_rate") or "0/1")
    if "/" in raw_rate:
        num, den = raw_rate.split("/", 1)
        rate = float(num) / float(den) if float(den) else 0.0
    else:
        rate = as_float(raw_rate) or 0.0
    check(technical, "frame rate", abs(rate - args.expect_fps) < 0.02, f"{rate:.3f} (expected {args.expect_fps})")

    frames = int(video.get("nb_read_frames") or video.get("nb_frames") or 0)
    check(technical, "frame count", frames == args.expect_frames,
          f"{frames} (expected {args.expect_frames})")

    duration = as_float(data.get("format", {}).get("duration")) or 0.0
    expected_duration = args.expect_frames / args.expect_fps
    check(technical, "duration", abs(duration - expected_duration) <= max(0.08, 1.5 / args.expect_fps),
          f"{duration:.3f}s (expected {expected_duration:.3f}s)")

    for label, key in (
        ("color primaries", "color_primaries"),
        ("color transfer", "color_transfer"),
        ("color space", "color_space"),
    ):
        value = str(video.get(key) or "")
        check(technical, label, value == "bt709", value or "missing")

    color_range = str(video.get("color_range") or "")
    if color_range:
        check(technical, "color range", color_range in {"tv", "mpeg"}, color_range)
    else:
        note(notes, "color range", "ffprobe did not report a range")

    if args.expect_audio == "yes":
        check(technical, "audio stream", audio is not None, "present" if audio else "missing")
    else:
        check(technical, "audio stream", audio is None, "absent" if audio is None else "unexpected audio")

    decode = run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "null", "-"])
    decode_error = (decode.stderr or "").strip()
    check(technical, "decode", decode.returncode == 0 and not decode_error,
          "clean" if decode.returncode == 0 and not decode_error else (decode_error[:180] or "ffmpeg failed"))

    blank = black_frames(path)
    if frames and blank >= frames:
        check(technical, "blank frames", False, f"{blank} of {frames} frames are black")
    else:
        check(technical, "blank frames", True, f"{blank} black frame(s)")
        if blank:
            note(notes, "black frames", f"{blank} frame(s) read as black. Confirm they are intentional.")

    white = white_frames(path)
    if white:
        note(notes, "possible flashes", f"{white} near-white frame(s). A cut can look like a flash. Inspect the stills.")
    else:
        note(notes, "possible flashes", "none detected by the white-frame pass")

    note(notes, "holds", freeze_notes(path) + ". A hold is not a failure.")
    bars = bar_note(path, width, height)
    if bars:
        note(notes, "crop", bars + ". Confirm the frame was composed for this aspect.")
    else:
        note(notes, "crop", "no large uniform border detected")

    notes.extend([
        {"name": "text readability", "detail": "Inspect the stills. This check does not read type."},
        {"name": "logo distortion", "detail": "Confirm a logo uses its own aspect ratio."},
        {"name": "source image distortion", "detail": "Confirm photographs use cover or contain, not a stretch."},
        {"name": "motion and transitions", "detail": "Watch the review file. Restrained motion is allowed."},
    ])

    ok = all(item["ok"] for item in technical)
    report = {
        "video": str(path),
        "technical_ok": ok,
        "technical": technical,
        "creative_notes": notes,
        "agent_review_required": True,
    }
    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    print("Technical")
    for item in technical:
        state = "PASS" if item["ok"] else "FAIL"
        print(f"  {state}  {item['name']}: {item['detail']}")
    print("Creative notes")
    for item in notes:
        print(f"  NOTE  {item['name']}: {item['detail']}")
    print("TECHNICAL PASS" if ok else "TECHNICAL FAIL")
    print("A passing encode is not design approval. Inspect the review file and stills.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
