# Hajeen AI - Frontend Application

A modern, professional Flutter application for interacting with multiple AI models with a clean, intuitive interface.

## Features

✨ **Modern UI/UX**
- Glassmorphism design elements
- Smooth animations and transitions
- Dark/Light theme support
- Full RTL/LTR language support (English & Arabic)

🤖 **AI Model Management**
- Dynamic model selection from Backend
- Real-time availability status
- Model capabilities display
- One-click model switching

💬 **Advanced Chat Interface**
- Real-time message streaming
- Comprehensive message actions (copy, regenerate, like, share, pin)
- Thinking indicators during processing
- Message threading and management

📁 **Rich File Support**
- Upload documents (PDF, Word, Excel, PowerPoint)
- Image handling (PNG, JPG, WebP, SVG)
- Video support (MP4, WebM)
- Audio files (MP3, WAV)

💳 **Subscription Management**
- Dynamic subscription plans
- Flexible billing cycles
- Feature-based plan differentiation
- Seamless checkout integration

🔧 **User Settings**
- Profile management
- Theme preferences
- Language selection
- Notification controls
- Privacy & security options

## Getting Started

### Prerequisites

- Flutter 3.0 or higher
- Dart 3.0 or higher
- iOS 11+ or Android 6+ (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/raedthawaba/AI-chat.git
   cd AI-chat
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update `lib/data/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-endpoint.com/v1';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/          # App configuration (theme, localization)
├── data/            # Data layer (models, services)
├── domain/          # Business logic (entities, usecases)
├── presentation/    # UI layer (screens, widgets)
├── providers/       # State management (Riverpod)
├── app.dart         # App root widget
└── main.dart        # Entry point
```

For detailed architecture documentation, see [FRONTEND_ARCHITECTURE.md](FRONTEND_ARCHITECTURE.md)

## Configuration

### API Connection

Ensure your Backend API provides the following endpoints:

**Models**
- `GET /models` - List available AI models

**Conversations**
- `GET /conversations` - List user's conversations
- `POST /conversations` - Create new conversation
- `GET /conversations/:id` - Get conversation details
- `PATCH /conversations/:id` - Update conversation
- `DELETE /conversations/:id` - Delete conversation

**Messages**
- `POST /conversations/:id/messages` - Send message (supports streaming)
- `POST /messages/:id/rating` - Rate message
- `POST /messages/:id/pin` - Pin message
- `POST /messages/:id/unpin` - Unpin message

**Subscriptions**
- `GET /subscription-plans` - List available plans
- `GET /subscriptions/current` - Get current subscription
- `POST /subscriptions/checkout` - Create checkout session

**Files**
- `POST /files/upload` - Upload file

### Environment Setup

1. **Development**
   ```bash
   flutter run --debug
   ```

2. **Production Build**
   ```bash
   flutter build apk --release        # Android
   flutter build ipa --release        # iOS
   ```

## Usage Examples

### Starting a Chat

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      initialMessage: 'Your message here',
      modelId: 'gpt-4',
    ),
  ),
);
```

### Accessing Current Theme

```dart
final isDarkMode = ref.watch(themeProvider);
```

### Getting Available Models

```dart
final aiModelsAsync = ref.watch(aiModelsProvider);
aiModelsAsync.when(
  data: (models) => ModelListView(models: models),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error: error),
);
```

## Supported Languages

- 🇺🇸 **English** (LTR)
- 🇸🇦 **العربية** (RTL)

Switch languages from Settings → Appearance → Language

## Customization

### Theme Colors

Edit `lib/config/theme/app_colors.dart` to customize:
- Primary color (brand)
- Accent colors
- Status colors (success, warning, error)
- Text colors

### Typography

Edit `lib/config/theme/app_typography.dart` to modify:
- Font families
- Font sizes
- Font weights
- Line heights
- Letter spacing

### Localization

Add new strings in `lib/config/localization/app_localization.dart`:

```dart
class Strings {
  static const String myNewString = 'English text';
}

class ArabicStrings {
  static const String myNewString = 'النص العربي';
}
```

## Performance Optimization

- ✅ Lazy loading for conversation lists
- ✅ Message streaming for real-time updates
- ✅ Local caching of frequently accessed data
- ✅ Optimized animations with minimal jank
- ✅ Efficient state management with Riverpod

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Generate coverage
flutter test --coverage
```

## Troubleshooting

### App crashes on startup
- Clear app data: `flutter clean`
- Rebuild: `flutter pub get && flutter run`

### Models not loading
- Check API connection
- Verify Backend API is running
- Check network permissions in manifests

### Theme not changing
- Restart the app after changing theme
- Check SharedPreferences permissions

### Language not switching
- Verify localization provider state
- Ensure supported locale is configured

## Dependencies

Key packages used:
- `riverpod: ^2.4.0` - State management
- `dio: ^5.3.0` - HTTP client
- `shared_preferences: ^2.2.0` - Local storage
- `animate_do: ^3.1.2` - Animations
- `intl: ^0.19.0` - Localization

See `pubspec.yaml` for complete list.

## Contributing

1. Create a feature branch
2. Make changes following code style
3. Test thoroughly
4. Submit pull request

## License

© 2024 Hajeen AI. All rights reserved.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: support@hajeen-ai.com

---

**Built with ❤️ using Flutter**
