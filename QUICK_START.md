# Hajeen AI Frontend - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Initial Setup

```bash
# Navigate to project
cd AI-chat

# Install dependencies
flutter pub get

# Get Riverpod code generation
flutter pub run build_runner build
```

### Step 2: Configure API Endpoint

Edit `lib/data/services/api_service.dart`:

```dart
static const String baseUrl = 'https://your-api-endpoint.com/v1';
```

### Step 3: Run the App

```bash
# For development
flutter run

# For specific device
flutter run -d <device_id>

# With hot reload
flutter run --hot
```

---

## 📱 Emulator Setup (Optional)

### Android Emulator
```bash
# Create emulator
flutter emulators --create --name Pixel_4

# List emulators
flutter emulators

# Run on emulator
flutter run -d emulator-5554
```

### iOS Simulator
```bash
# Open simulator
open -a Simulator

# Run on simulator
flutter run -d iPhone\ 14
```

---

## 🏗️ Project Structure Quick Reference

```
lib/
├── main.dart              ← App entry point
├── app.dart               ← Root widget with theme/localization
├── config/                ← App configuration
├── data/                  ← Models & API services
├── presentation/          ← Screens & widgets
└── providers/             ← State management
```

---

## 🔌 API Integration Checklist

- [ ] Backend API running
- [ ] Base URL configured in `api_service.dart`
- [ ] Authentication endpoint ready
- [ ] All required endpoints implemented
- [ ] CORS configured for local development
- [ ] File upload endpoint ready
- [ ] Streaming/SSE endpoints ready

---

## 🎨 Customization Quick Tips

### Change Primary Color
Edit `lib/config/theme/app_colors.dart`:
```dart
static const primary = Color(0xFF6366F1); // Change this
```

### Add New Language
1. Add strings in `lib/config/localization/app_localization.dart`
2. Add locale to `supportedLocales`
3. Rebuild code generation

### Modify Fonts
Edit `pubspec.yaml` fonts section and `lib/config/theme/app_theme.dart`

### Add New Screen
1. Create in `lib/presentation/screens/`
2. Add route in `main_layout.dart`
3. Add navigation button

---

## 🧪 Testing Quick Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart

# Update snapshots
flutter test --update-goldens
```

---

## 🔍 Debugging

### View logs
```bash
flutter logs
```

### Debug mode
```bash
flutter run -vv  # Very verbose
```

### Performance profiling
1. Run app: `flutter run`
2. In DevTools: Performance tab
3. Record and analyze

### State inspection
1. Enable Riverpod logging
2. Watch provider values in console

---

## 📦 Build for Production

### Android
```bash
# Create APK
flutter build apk --release

# Create App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build framework
flutter build ios --release

# Archive for App Store
xcode-select --switch /Applications/Xcode.app/Contents/Developer
flutter build ios --release
```

---

## 🚀 Deployment Steps

1. **Configuration**
   - Update API Base URL for production
   - Configure error logging
   - Setup analytics

2. **Build**
   ```bash
   flutter clean
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

3. **Sign**
   - Android: Configure signing in `android/app/build.gradle`
   - iOS: Configure code signing in Xcode

4. **Upload**
   - Android: Google Play Console
   - iOS: App Store Connect

---

## 📞 Troubleshooting

### App Won't Start
```bash
flutter clean
flutter pub get
flutter run
```

### Build Errors
```bash
flutter pub upgrade
flutter clean
flutter pub get
flutter run
```

### API Connection Issues
- Check Base URL configuration
- Verify Backend is running
- Check network connectivity
- Review API response format

### State Management Issues
```bash
# Rebuild Riverpod providers
flutter pub run build_runner watch
```

---

## 📚 Important Files to Know

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point |
| `lib/app.dart` | App configuration |
| `lib/data/services/api_service.dart` | API endpoints |
| `lib/providers/api_provider.dart` | Riverpod setup |
| `lib/config/theme/app_theme.dart` | Theme definition |
| `pubspec.yaml` | Dependencies |

---

## 🔐 Security Tips

- Always use HTTPS for API calls
- Don't commit API keys to Git
- Store tokens securely
- Use environment variables for sensitive data
- Enable ProGuard for Android release builds
- Code sign all iOS builds

---

## 📈 Performance Tips

- Use Profile mode for testing: `flutter run --profile`
- Minimize rebuilds with `Consumer`
- Use `const` for widgets
- Cache network images
- Lazy load long lists
- Profile with DevTools

---

## 🆘 Getting Help

1. Check `FRONTEND_ARCHITECTURE.md` for detailed docs
2. Review `IMPLEMENTATION_SUMMARY.md` for overview
3. Check Flutter documentation: https://flutter.dev
4. Check Riverpod docs: https://riverpod.dev
5. Review commit history for changes

---

## ✅ Verification Checklist

- [ ] Dependencies installed: `flutter pub get`
- [ ] No build errors: `flutter run`
- [ ] Home screen loads
- [ ] Theme toggle works
- [ ] Language switch works
- [ ] Model selector functional
- [ ] API endpoints configured
- [ ] No console errors

---

## 🎯 Next Actions

1. **Connect Backend**
   - Configure API Base URL
   - Test authentication
   - Verify all endpoints

2. **Customize**
   - Update colors/fonts
   - Customize strings
   - Adjust layouts

3. **Deploy**
   - Build release versions
   - Sign applications
   - Upload to app stores

4. **Monitor**
   - Setup error tracking
   - Configure analytics
   - Monitor performance

---

**You're ready to go! Start by configuring your API endpoint and running `flutter run`.**

For detailed documentation, see:
- 📖 [FRONTEND_ARCHITECTURE.md](FRONTEND_ARCHITECTURE.md)
- 📋 [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- ✅ [COMPLETION_CHECKLIST.md](COMPLETION_CHECKLIST.md)
- 📖 [README_FRONTEND.md](README_FRONTEND.md)
