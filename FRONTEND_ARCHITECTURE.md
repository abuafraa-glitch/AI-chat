# Hajeen AI - Frontend Architecture Documentation

## Overview

Hajeen AI Frontend is a modern, scalable Flutter application built with clean architecture principles, Riverpod state management, and full support for RTL/LTR languages and dark/light themes.

## Technology Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod 2.4.0
- **HTTP Client**: Dio 5.3.0
- **Local Storage**: SharedPreferences 2.2.0, SQLite 2.3.0
- **Localization**: Intl 0.19.0
- **Animations**: Animate_do 3.1.2, flutter_staggered_animations 0.1.3
- **UI Components**: Material 3

## Project Structure

```
lib/
├── config/
│   ├── theme/
│   │   ├── app_colors.dart          # Color palette and schemes
│   │   ├── app_typography.dart      # Typography styles
│   │   └── app_theme.dart           # Light/Dark theme definitions
│   └── localization/
│       └── app_localization.dart    # i18n configuration
│
├── data/
│   ├── models/
│   │   ├── ai_model.dart           # AI Model data class
│   │   ├── conversation.dart       # Conversation data class
│   │   ├── message.dart            # Message data class
│   │   └── subscription.dart       # Subscription/Plan data classes
│   │
│   ├── services/
│   │   ├── api_service.dart        # REST API client
│   │   └── storage_service.dart    # Local storage management
│   │
│   └── repositories/
│       # Future: Repository pattern implementations
│
├── domain/
│   ├── entities/
│   │   # Domain models for business logic
│   └── usecases/
│       # Future: Use case implementations
│
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart              # Main landing screen
│   │   ├── chat_screen.dart              # Chat interface with streaming
│   │   ├── conversations_screen.dart     # Conversation management
│   │   ├── subscription_screen.dart      # Subscription plans
│   │   ├── settings_screen.dart          # User settings
│   │   └── main_layout.dart              # Main navigation
│   │
│   └── widgets/
│       ├── model_selector.dart           # Dynamic model selection
│       ├── chat_input_field.dart         # Message input with attachments
│       ├── suggestion_chips.dart         # Quick suggestion chips
│       └── message_bubble.dart           # Message display with actions
│
├── providers/
│   ├── api_provider.dart            # API service and data providers
│   ├── storage_provider.dart        # Storage service provider
│   ├── theme_provider.dart          # Theme state management
│   └── localization_provider.dart   # Language state management
│
├── app.dart                         # App configuration
└── main.dart                        # Entry point
```

## Key Features

### 1. Dynamic Model Selection
- Models are loaded from Backend API
- Bottom Sheet UI with real-time availability status
- No hardcoded model information
- Automatic updates when new models are added

### 2. Chat Interface
- Real-time message streaming with visual feedback
- Message bubbles with comprehensive actions:
  - Copy
  - Regenerate
  - Like/Dislike
  - Share
  - Pin
- Thinking indicator during AI response generation

### 3. Conversation Management
- Search functionality across conversations
- Pin important conversations
- Archive old conversations
- Delete with confirmation
- Message count tracking
- Last message preview

### 4. Theme System
- Full dark/light mode support
- Smooth transitions between themes
- Theme persistence using SharedPreferences
- Material 3 compliant design tokens

### 5. Localization
- Complete Arabic (RTL) and English (LTR) support
- Automatic text direction based on language
- Language preference persistence
- All UI strings from centralized string classes

### 6. Subscription Management
- Dynamic subscription plans from Backend
- Plan feature display
- Current subscription status
- Checkout integration ready
- No hardcoded pricing or limits

### 7. Settings & User Management
- Profile management
- Language and theme preferences
- Notification settings
- Privacy and security options
- Account deletion with confirmation
- Logout functionality

## State Management with Riverpod

### Providers Overview

```dart
// API Data
final aiModelsProvider           // List of available AI models
final conversationsProvider      // User's conversations
final subscriptionPlansProvider  // Available subscription plans
final currentSubscriptionProvider // User's current subscription

// UI State
final themeProvider             // Dark/Light mode
final localizationProvider      // Selected language
final selectedModelProvider     // Currently selected AI model
final authTokenProvider         // Authentication token
```

### Provider Pattern Usage

```dart
// Watching providers
final models = ref.watch(aiModelsProvider);

// Modifying state
ref.read(themeProvider.notifier).toggleTheme();

// FutureProvider for async data
final plansAsync = ref.watch(subscriptionPlansProvider);
plansAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
  data: (plans) => PlansList(plans: plans),
);
```

## API Integration

### ApiService Features

The `ApiService` class handles all backend communication:

```dart
// Models
await apiService.getAvailableModels()

// Conversations
await apiService.getConversations()
await apiService.createConversation(title, modelId)
await apiService.getConversation(id)
await apiService.updateConversation(id, ...)
await apiService.deleteConversation(id)

// Messages with Streaming
final stream = await apiService.sendMessage(...)
await for (final chunk in stream) {
  // Process streamed response
}

// Message Actions
await apiService.updateMessageRating(messageId, isPositive)
await apiService.pinMessage(messageId)
await apiService.unpinMessage(messageId)

// Subscriptions
await apiService.getCurrentSubscription()
await apiService.getSubscriptionPlans()
await apiService.createCheckoutSession(planId)

// Files
await apiService.uploadFile(filePath)
```

### API Base Configuration

- **Base URL**: `https://api.hajeen-ai.com/v1`
- **Default Timeout**: 30 seconds
- **Authentication**: Bearer token in Authorization header
- **Error Handling**: Global interceptor for 401 responses

## Data Models

### Message Model
```dart
Message(
  id: String,
  conversationId: String,
  content: String,
  role: MessageRole (user, assistant, system),
  timestamp: DateTime,
  modelId: String?,
  attachments: List<MessageAttachment>?,
  likeCount: int,
  dislikeCount: int,
  isLiked: bool,
  isDisliked: bool,
  isPinned: bool,
  isStreaming: bool,
  streamingProgress: double?,
)
```

### Conversation Model
```dart
Conversation(
  id: String,
  title: String,
  description: String?,
  userId: String,
  currentModelId: String,
  createdAt: DateTime,
  updatedAt: DateTime,
  messages: List<Message>,
  isPinned: bool,
  isArchived: bool,
  messageCount: int,
  lastMessage: String?,
)
```

### Subscription Plan Model
```dart
SubscriptionPlan(
  id: String,
  name: String,
  description: String,
  price: double,
  currency: String,
  billingCycleDays: int,
  messagesPerDay: int,
  maxFileSize: int,
  availableModels: List<String>,
  features: List<String>,
  isPremium: bool,
)
```

## Theme System

### Color Palette

**Brand Colors:**
- Primary: Indigo (#6366F1)
- Accent: Cyan (#06B6D4)
- Success: Green (#10B981)
- Warning: Amber (#F59E0B)
- Error: Red (#EF4444)

**Neutral Colors:**
- Light Background: #FAFAFA
- Light Surface: #FFFFFF
- Dark Background: #0F0F0F
- Dark Surface: #1A1A1A

### Typography

**Font Families:**
1. **Gilroy** - Headlines and display text
   - Bold, SemiBold, Medium, Regular weights
2. **Inter** - Body text and labels
   - Bold, SemiBold, Medium, Regular weights

**Text Styles:**
- Display: 32-48px
- Headline: 20-28px
- Title: 14-18px
- Body: 12-16px
- Label: 11-14px

## Localization

### Supported Languages
- English (en) - LTR
- العربية (ar) - RTL

### String Management

```dart
// In English
Strings.welcome = 'Welcome to Hajeen AI'

// In Arabic
ArabicStrings.welcome = 'أهلاً في Hajeen AI'
```

All strings are centralized in `app_localization.dart` for easy maintenance.

## Best Practices

### 1. Always Fetch from Backend
- No hardcoded data for models, plans, or features
- All dynamic content comes from API
- Scalable for future additions

### 2. State Management
- Use Riverpod providers for all state
- Leverage StateNotifier for mutable state
- Use FutureProvider for async data

### 3. Error Handling
- Show user-friendly error messages
- Log errors for debugging
- Implement retry logic for failed requests

### 4. Performance
- Use lazy loading for long lists
- Implement pagination for conversations
- Cache frequently accessed data
- Optimize animations for smooth UX

### 5. RTL/LTR Support
- Use `TextDirection` and `Directionality` widgets
- Test layout in both directions
- Use flexbox appropriately for direction changes

### 6. Accessibility
- Add meaningful content descriptions
- Ensure sufficient color contrast
- Support screen readers
- Use semantic widgets

## File Upload Support

The chat input field supports:
- **Documents**: PDF, Word (.docx), Excel (.xlsx), PowerPoint (.pptx)
- **Images**: PNG, JPG, WebP, SVG
- **Video**: MP4, WebM
- **Audio**: MP3, WAV
- **Archives**: ZIP, RAR

Files are uploaded via `ApiService.uploadFile()` and associated with messages.

## Future Enhancements

1. **Offline Support**
   - Sync conversations when online
   - Draft messages saved locally

2. **Advanced Search**
   - Full-text search across conversations
   - Filter by model, date, etc.

3. **Collaboration**
   - Share conversations with others
   - Collaborative chat rooms

4. **Analytics**
   - Usage statistics
   - Model performance tracking

5. **Advanced Features**
   - Code syntax highlighting
   - Markdown rendering
   - Voice input/output

## Deployment Checklist

- [ ] API Base URL configured for production
- [ ] Error logging configured
- [ ] Analytics integrated
- [ ] Push notifications configured
- [ ] Deep linking setup
- [ ] App signing configured
- [ ] Testing completed
- [ ] Performance profiled

## Support & Troubleshooting

### Common Issues

1. **Models not loading**
   - Check API connectivity
   - Verify authorization token
   - Check Backend API response

2. **Messages not streaming**
   - Verify WebSocket/SSE configuration
   - Check network stability
   - Review API error logs

3. **Theme not persisting**
   - Ensure SharedPreferences initialized
   - Check storage permissions
   - Verify storage key naming

4. **Language not changing**
   - Verify localization provider state
   - Restart app for complete refresh
   - Check device language settings

## Contact & Maintenance

For issues, feature requests, or maintenance:
- Check the Backend API documentation
- Review Flutter documentation
- Test in device emulator
- Profile performance with DevTools
