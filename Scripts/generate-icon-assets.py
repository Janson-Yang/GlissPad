#!/usr/bin/env python3
from __future__ import annotations

from math import atan2, cos, sin
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Sources" / "GlissPad" / "Resources" / "Icons"

def line(x1: float, y1: float, x2: float, y2: float, width: float = 2.1) -> str:
    return f'<path d="M{x1:g} {y1:g} L{x2:g} {y2:g}" stroke-width="{width:g}"/>'


def path(d: str, width: float = 2.1, fill: str = "none") -> str:
    return f'<path d="{d}" stroke-width="{width:g}" fill="{fill}"/>'


def dot(x: float, y: float, r: float = 2.2, opacity: float = 1) -> str:
    return f'<circle cx="{x:g}" cy="{y:g}" r="{r:g}" fill="#000" stroke="none" opacity="{opacity:g}"/>'


def circle(x: float, y: float, r: float, width: float = 2.2) -> str:
    return f'<circle cx="{x:g}" cy="{y:g}" r="{r:g}" fill="none" stroke-width="{width:g}"/>'


def rect(x: float, y: float, w: float, h: float, radius: float = 3, width: float = 2) -> str:
    return f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" rx="{radius:g}" stroke-width="{width:g}"/>'


def polygon(points: list[tuple[float, float]], width: float = 2) -> str:
    pts = " ".join(f"{x:g},{y:g}" for x, y in points)
    return f'<polygon points="{pts}" stroke-width="{width:g}"/>'


def arrow(x1: float, y1: float, x2: float, y2: float, width: float = 2.1) -> str:
    angle = atan2(y2 - y1, x2 - x1)
    left = (x2 - 4 * cos(angle - 0.7), y2 - 4 * sin(angle - 0.7))
    right = (x2 - 4 * cos(angle + 0.7), y2 - 4 * sin(angle + 0.7))
    return line(x1, y1, x2, y2, width) + line(left[0], left[1], x2, y2, width) + line(right[0], right[1], x2, y2, width)


def dots(count: int, y: float = 23, opacity: float = 1) -> str:
    start = 16 - (count - 1) * 4
    return "".join(dot(start + index * 8, y, opacity=opacity) for index in range(count))


def tap(count: int) -> str:
    icons = []
    start = 16 - (count - 1) * 4
    for index in range(count):
        x = start + index * 8
        icons.append(path(f"M{x - 4} 12 C{x - 4} 7 {x + 4} 7 {x + 4} 12 L{x + 4} 16 C{x + 4} 20 {x - 4} 20 {x - 4} 16 Z", 1.9))
        icons.append(path(f"M{x - 4} 24 C{x - 2} 26 {x + 2} 26 {x + 4} 24", 1.8))
    return "".join(icons)


def one_finger_tap() -> str:
    return path("M10 12 C10 6 22 6 22 12 L22 16 C22 22 10 22 10 16 Z", 2) + path("M10 25 C13 28 19 28 22 25", 1.9)


def one_finger_double_tap() -> str:
    first = path("M8 13 C8 8 14 8 14 13 L14 16 C14 19 8 19 8 16 Z", 1.8) + path("M7 23 C9 25 13 25 15 23", 1.6)
    second = path("M18 10 C18 5 26 5 26 10 L26 15 C26 19 18 19 18 15 Z", 1.8) + path("M17 23 C19 26 25 26 27 23", 1.6)
    return first + second


def two_finger_tap() -> str:
    left = path("M8 12 C8 8 14 8 14 12 L14 16 C14 20 8 20 8 16 Z", 1.9)
    right = path("M18 12 C18 8 24 8 24 12 L24 16 C24 20 18 20 18 16 Z", 1.9)
    return left + right + path("M7 24 C9 26 13 26 15 24", 1.6) + path("M17 24 C19 26 23 26 25 24", 1.6)


def two_finger_tip_tap() -> str:
    fixed = circle(9, 22, 3, 1.8)
    tapper = path("M17 10 C17 6 25 6 25 10 L25 15 C25 19 17 19 17 15 Z", 1.9)
    return fixed + tapper + path("M16 24 C19 27 23 27 26 24", 1.7)


def pressure(count: int) -> str:
    return dots(count) + path("M7 13 C10 9 22 9 25 13") + path("M10 16 C12 14 20 14 22 16", 1.8)


def swipe(count: int, direction: str = "right") -> str:
    base = dots(count, y=24)
    if direction == "left":
        return base + arrow(24, 12, 8, 12)
    if direction == "up":
        return base + arrow(16, 22, 16, 8)
    return base + arrow(8, 12, 24, 12)


def hold(count: int) -> str:
    clock = '<circle cx="16" cy="11" r="6.5" fill="none" stroke-width="2"/>'
    return dots(count) + clock + line(16, 11, 16, 7, 1.7) + line(16, 11, 20, 13, 1.7)


def tip_tap(count: int) -> str:
    fixed = dots(max(1, count - 1), y=24, opacity=0.35)
    moving_x = 16 + (count - 1) * 4
    return fixed + dot(moving_x, 24) + line(moving_x, 7, moving_x, 15)


def tip_swipe(count: int) -> str:
    fixed = dots(max(1, count - 1), y=24, opacity=0.35)
    moving_x = 16 + (count - 1) * 4
    return fixed + dot(moving_x, 24) + path(f"M{moving_x} 22 C{moving_x - 2} 16 {moving_x + 7} 13 {moving_x + 3} 8")


def pinch(inward: bool) -> str:
    body = dot(10, 20) + dot(22, 12)
    return body + (arrow(4, 26, 11, 19) + arrow(28, 6, 21, 13) if inward else arrow(11, 19, 4, 26) + arrow(21, 13, 28, 6))


def shape(kind: str) -> str:
    if kind == "circle":
        return circle(16, 16, 8)
    if kind == "square":
        return rect(8, 8, 16, 16, 1.5, 2.2)
    return polygon([(16, 7), (25, 24), (7, 24)], 2.2)


def drawing(count: int) -> str:
    return dots(count, y=25, opacity=0.45) + path("M7 18 C11 7 16 27 21 13 C23 8 25 12 25 18")


def custom_path() -> str:
    anchors = dot(7, 22, 2) + dot(16, 10, 2) + dot(25, 17, 2)
    route = path("M7 22 C9 15 12 10 16 10 C20 10 22 17 25 17", 2.2)
    return route + anchors


def drawn_custom_path() -> str:
    pen = path("M18 6 L27 15 L15 27 L8 29 L10 22 Z", 2)
    stroke = path("M6 17 C9 12 12 16 14 11", 2)
    return stroke + pen + line(18, 6, 27, 15, 1.4)


def two_finger_region_swipe() -> str:
    region = rect(5, 5, 22, 15, 4, 2)
    return region + arrow(10, 12.5, 22, 12.5, 1.8) + dots(2, y=26)


def category(count: int) -> str:
    spacing = 5
    start = 16 - (count - 1) * spacing / 2
    centered_dots = "".join(dot(start + index * spacing, 16, 1.7) for index in range(count))
    return rect(5, 6, 22, 18, 4, 1.7) + centered_dots


def thumb_scale() -> str:
    return dot(8, 21, 3.1) + dot(21, 12, 1.8) + dot(24, 20, 1.8) + arrow(12, 19, 17, 16) + arrow(20, 15, 25, 12)


def action_icon(kind: str) -> str:
    if kind == "script":
        return rect(6, 8, 20, 16, 3) + path("M10 13 L14 16 L10 19") + line(17, 20, 23, 20)
    if kind == "keyboard":
        return rect(5, 9, 22, 14, 3) + "".join(dot(x, y, 1.2) for y in (14, 18) for x in (10, 14, 18, 22))
    if kind == "hud":
        return rect(7, 8, 18, 15, 3) + dot(13, 15, 2) + line(17, 13, 22, 13) + line(17, 18, 21, 18)
    return path("M16 6 A10 10 0 1 1 15.9 6") + line(16, 16, 16, 10) + line(16, 16, 21, 18)


ICONS: dict[str, str] = {
    "category-one-finger": category(1),
    "category-two-finger": category(2),
    "category-three-finger": category(3),
    "action-script": action_icon("script"),
    "action-keyboard": action_icon("keyboard"),
    "action-hud": action_icon("hud"),
    "action-latency": action_icon("latency"),
    "trigger-one-finger-touch-start": dot(16, 23) + arrow(16, 8, 16, 16),
    "trigger-one-finger-long-press": hold(1),
    "trigger-one-finger-circle": shape("circle"),
    "trigger-one-finger-square": shape("square"),
    "trigger-one-finger-triangle": shape("triangle"),
    "trigger-one-finger-corner-click": rect(6, 6, 20, 20, 4) + dot(9, 9) + arrow(16, 18, 9, 9),
    "trigger-one-finger-tap": one_finger_tap(),
    "trigger-one-finger-double-tap": one_finger_double_tap(),
    "trigger-one-finger-press": pressure(1),
    "trigger-one-finger-custom-path": custom_path(),
    "trigger-one-finger-drawn-path": drawn_custom_path(),
    "trigger-two-finger-touch-start": dots(2) + arrow(16, 8, 16, 15),
    "trigger-two-finger-tap": two_finger_tap(),
    "trigger-two-finger-tip-tap": two_finger_tip_tap(),
    "trigger-two-finger-pinch-in": pinch(True),
    "trigger-two-finger-pinch-out": pinch(False),
    "trigger-two-finger-free-swipe": swipe(2),
    "trigger-two-finger-region-swipe": two_finger_region_swipe(),
    "trigger-three-finger-force-press": pressure(3),
    "trigger-top-left-force-press": rect(6, 6, 20, 20, 4) + dot(9, 9) + pressure(1),
    "trigger-left-edge-two-finger-swipe": line(5, 6, 5, 26) + swipe(2),
    "trigger-two-finger-hold": hold(2),
    "trigger-top-right-click": rect(6, 6, 20, 20, 4) + dot(23, 9) + tap(1),
    "trigger-release-last-finger": dots(3, y=24, opacity=0.45) + arrow(20, 23, 20, 9),
    "trigger-three-finger-touch": dots(3) + arrow(16, 8, 16, 15),
    "trigger-three-finger-tap": tap(3),
    "trigger-three-finger-press": pressure(3),
    "trigger-three-finger-swipe": swipe(3),
    "trigger-three-finger-tip-tap": tip_tap(3),
    "trigger-three-finger-tip-swipe": tip_swipe(3),
    "trigger-thumb-two-finger-scale": thumb_scale(),
    "trigger-three-finger-drawing": drawing(3),
}

def document(body: str) -> str:
    return "\n".join([
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">',
        '<g fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round">',
        body,
        "</g>",
        "</svg>",
        "",
    ])

def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for icon_name, body in sorted(ICONS.items()):
        (OUT / f"{icon_name}.svg").write_text(document(body), encoding="utf-8")

if __name__ == "__main__":
    main()
