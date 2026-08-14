# Changelog

All notable changes to this project will be documented in this file.

## 1.0.1

* Updated repository, homepage, and issue tracker URLs to point to GitHub.

## 1.0.0

* **Initial Stable Release** of `flutter_visual_test_runner`.
* **Zero-Friction In-App Test Dashboard**:
  * Seamless root overlay integration wrapping `MaterialApp`, `CupertinoApp`, and `WidgetsApp`.
  * Minimized draggable floating badge showing live pass/fail status and progress counters.
  * Glassmorphic expandable drawer with scenario/test tree view, individual test playback, and real-time logs.
* **Cyberpunk Visual Overlays**:
  * Animated glowing neon bounding boxes with pulsing technical corner brackets and center crosshair ripples.
  * Realistic touch shockwave indicators for taps, double-taps, long-presses, drags, and typing.
  * Floating top HUD banner with dynamic step description and status icons.
* **Natural English & Markdown Test DSL**:
  * Human-readable step actions (`Tap`, `Enter ... into ...`, `Expect ... to be visible`, `Scroll down`, `Wait`).
  * Direct support for Markdown (`.md`), Plain Text (`.txt`), and YAML (`.yaml`) test specification files.
* **Intelligent `TestCaseConverter`**:
  * Auto-converts loose informal intent descriptions (`test login`, `test dashboard`, `test add to cart`) into full canonical test suites.
  * Custom domain-specific intent template registration (`TestCaseConverter.registerTemplate`).
* **Interactive Test Controls & Step Debugger**:
  * Play, Pause, Resume, Step-by-Step execution mode.
  * Configurable speed multipliers (`0.25x`, `0.5x`, `1.0x`, `2.0x`, `4.0x`).
  * Support for `autoStart` and `autoStartDelay`.
* **Intelligent Target Discovery & Viewport Auto-Scroll**:
  * Scoped element matching by Key, Text, Type, Semantics, Tooltip, Hint, and Smart Fuzzy query.
  * Automatically calculates off-screen coordinates in scrollable widgets and smoothly scrolls targets into view.
* **Standalone HTML & JSON Test Report Generation**:
  * Export styled interactive HTML execution reports with metric cards and step timelines.
  * JSON and Markdown report serialization.
