# Flutter Visual Test Runner - Example Application

This example demonstrates how to integrate and use **Flutter Visual Test Runner** in a realistic e-commerce application.

---

## 🚀 Running the Example

1. Ensure a device or emulator is connected:
   ```bash
   flutter devices
   ```

2. Run the application:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

* **`lib/main.dart`**: Sets up `VisualTestRunner.fromAsset(...)` with auto-start and speed controls.
* **`lib/screens/login_screen.dart`**: Phone and password authentication screen with input validation.
* **`lib/screens/dashboard_screen.dart`**: Store dashboard with revenue metrics, catalog items, and shopping cart counter.
* **`assets/test_specs/plain_english_tests.txt`**: Natural language test specification covering negative validation, successful sign-in, and shopping cart interactions.
