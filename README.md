# 🚀 Flutter Visual Test Runner

[![pub package](https://img.shields.io/pub/v/flutter_visual_test_runner.svg)](https://pub.dev/packages/flutter_visual_test_runner)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/flutter-visual-test-runner/flutter_visual_test_runner/blob/main/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-v3.0+-02569B.svg?logo=flutter)](https://flutter.dev)

A powerful in-app visual test runner dashboard for Flutter applications. It enables developers, QA engineers, and product teams to **visually watch automated tests execute live** on physical devices and emulators, highlight target widgets with glowing cybernetic indicators, simulate realistic pointer gestures, step through tests like a debugger, and export interactive HTML/JSON reports.

---

## ✨ Highlights & Features

- **⚡ Zero-Friction Setup**: Wrap any Flutter app (`MaterialApp`, `CupertinoApp`, `WidgetsApp`) with `VisualTestRunner` in 2 lines of code.
- **🗣️ Plain English & Markdown DSL**: Write tests in conversational English (`test empty phone validation`, `Enter "123" into phone_input`, `Tap "Sign In"`).
- **🪄 Intelligent `TestCaseConverter`**: Write ultra-short intents (`test login`, `test dashboard`, `test add to cart`) and let the converter automatically generate full canonical test steps.
- **🎯 Smart Target Discovery**: Scoped widget discovery prioritizing buttons and exact matches by `Key`, `Text`, `Type`, `Semantics`, `Tooltip`, `Hint`, or fuzzy smart query.
- **📜 Automatic Scroll Into View**: Off-screen elements in `ListView`, `GridView`, or `SingleChildScrollView` are automatically calculated and scrolled into view before interacting.
- **🔮 Cyberpunk Visual Highlights**:
  - Animated glowing neon bounding boxes with pulsing technical corner brackets and crosshair indicators.
  - Expanding touch shockwave ripples on taps, double-taps, long-presses, and typing.
  - Floating top HUD banner displaying current scenario, test case, and live step status.
- **🎛️ Glassmorphic Control Dashboard**:
  - Minimized draggable floating badge showing live pass/fail counts.
  - Expandable drawer with scenario/test tree view, individual test playback, speed sliders (`0.25x` to `4.0x`), and breakpoint debugging (`Step Mode`).
- **📟 Live Execution Console**: Filterable logs, stack traces, and copyable execution output.
- **📊 Standalone HTML & JSON Report Exporter**: Generate interactive styled HTML test reports with executive metrics and step execution timelines.

---

## 📦 Installation

Add `flutter_visual_test_runner` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_visual_test_runner: ^1.0.0
```

Run `flutter pub get`.

---

## 🚀 Quick Start (2 Lines in `main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

void main() {
  runApp(
    VisualTestRunner.fromAsset(
      specPath: 'assets/test_specs/tests.txt',
      autoStart: true,
      initialSpeed: 1.0,
      child: const MyApp(),
    ),
  );
}
```

---

## ✍️ Flexible Ways to Define Test Cases

### 1. From an Asset File (`.txt`, `.md`, `.yaml`, or `.json`)

Create an asset file `assets/test_specs/tests.txt`:

```text
# Scenario: Authentication & Verification @smoke @auth

## Test: test empty phone validation
- Tap "Sign In"
- Expect "Phone number is required" to be visible

## Test: test short phone number validation
- Enter "123" into phone_input
- Tap "Sign In"
- Expect "Phone number must be at least 10 digits" to be visible

## Test: test successful sign in with valid credentials
- Enter "08012345678" into phone_input
- Enter "Secret123" into password_input
- Tap "Sign In"
- Expect "Store Dashboard" to be visible
- Expect "Welcome back, Alex!" to be visible

# Scenario: Store Catalog & Cart Interactions @catalog

## Test: add products to cart and verify cart badge
- Tap "add_btn_1"
- Expect "Added ✓" to be visible
- Expect "cart_badge" to be visible
- Tap "add_btn_2"
- Expect "cart_badge" to be visible
```

Declare the asset in your `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/test_specs/
```

Load it into the runner:
```dart
VisualTestRunner.fromAsset(
  specPath: 'assets/test_specs/tests.txt',
  autoStart: true,
  child: const MyApp(),
);
```

---

### 2. Loose Natural Language & `TestCaseConverter`

Users don't even need to write verbose steps. You can pass high-level intents directly:

```dart
VisualTestRunner.fromNaturalLanguage(
  '''
  test login
  test dashboard
  test add to cart
  ''',
  autoStart: true,
  child: const MyApp(),
);
```

[`TestCaseConverter`](lib/src/dsl/test_case_converter.dart) automatically expands high-level shortcuts and conversational commands:
```text
type "08012345678" in phone_input
type "Secret123" in password_input
click Sign In
see Store Dashboard
tap add_btn_1
ensure cart_badge is visible
```

You can also register your own domain-specific templates:
```dart
TestCaseConverter.registerTemplate(
  RegExp(r'checkout with coupon (.+)', caseSensitive: false),
  (match) => [
    '- Enter "${match.group(1)}" into coupon_input',
    '- Tap "Apply Coupon"',
    '- Tap "Checkout"',
    '- Expect "Order Summary" to be visible',
  ],
);
```

---

### 3. Strongly Typed Dart API

```dart
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

final appTestSuite = TestSuite(
  name: 'Main App Test Suite',
  scenarios: [
    TestScenario(
      name: 'Authentication Flow',
      tags: ['@auth'],
      cases: [
        TestCase(
          name: 'Invalid Phone Number Validation',
          steps: [
            TestStep.enterText(
              target: TargetFinder.byKey('phone_input'),
              text: '123',
              description: 'Enter invalid phone number',
            ),
            TestStep.tap(
              target: TargetFinder.byText('Sign In'),
              description: 'Tap Sign In button',
            ),
            TestStep.expectVisible(
              target: TargetFinder.byText('Phone number must be at least 10 digits'),
              description: 'Verify error banner is displayed',
            ),
          ],
        ),
      ],
    ),
  ],
);

VisualTestRunner(
  suite: appTestSuite,
  child: const MyApp(),
);
```

---

## 🎯 Target Finders & Lookup Strategies

| Finder | Description | Example |
|---|---|---|
| `TargetFinder.smart('...')` | Fuzzy lookup checking keys, text, hints, buttons, and semantic labels | `TargetFinder.smart('Sign In')` |
| `TargetFinder.byKey('...')` | Locates by Flutter `Key` or key name | `TargetFinder.byKey('phone_input')` |
| `TargetFinder.byText('...')` | Locates by exact or substring text content | `TargetFinder.byText('Store Dashboard')` |
| `TargetFinder.byType(Widget)` | Locates by widget class type | `TargetFinder.byType(ElevatedButton)` |
| `TargetFinder.byHint('...')` | Locates input fields by hint / label text | `TargetFinder.byHint('Phone Number')` |
| `TargetFinder.byTooltip('...')`| Locates by tooltip text | `TargetFinder.byTooltip('Cart')` |
| `TargetFinder.byIcon(IconData)`| Locates by icon data | `TargetFinder.byIcon(Icons.shopping_bag)` |

---

## 🎛️ Runner Configuration Options

| Parameter | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Set to `false` in production releases to bypass the runner. |
| `autoStart` | `bool` | `false` | When `true`, automatically begins test execution on app startup. |
| `autoStartDelay` | `Duration` | `500ms` | Delay after app mount before running auto-started tests. |
| `initialSpeed` | `double` | `1.0` | Execution speed multiplier (`0.25x`, `0.5x`, `1.0x`, `2.0x`, `4.0x`). |
| `specPath` | `String?` | `null` | Path to an asset test specification file (`.txt`, `.md`, `.yaml`, `.json`). |
| `specText` | `String?` | `null` | Raw natural language test specification string. |
| `suite` | `TestSuite?` | `null` | Pre-built strongly typed `TestSuite` instance. |

---

## 📊 Exporting HTML & JSON Reports

Generate standalone, beautifully formatted reports at the end of a test run:

```dart
final report = await controller.runAll();

// 1. Export as interactive HTML
final htmlReport = TestReportExporter.toHtml(report!);

// 2. Export as JSON
final jsonReport = TestReportExporter.toJson(report);

// 3. Export as Markdown
final markdownReport = TestReportExporter.toMarkdown(report);
```

---

## 📱 Example App

A full demonstration application is included in the [`example/`](example/) directory:
```bash
cd example
flutter run
```

---

## 📄 License

MIT License. Developed for the Flutter developer and QA community.
