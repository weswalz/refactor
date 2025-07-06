# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**Open Project:**
```bash
open "LED MESSENGER.xcodeproj"
```

**Build for iOS Simulator:**
```bash
xcodebuild -project "LED MESSENGER.xcodeproj" -scheme "LED MESSENGER" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

**Build for iPad Simulator:**
```bash
xcodebuild -project "LED MESSENGER.xcodeproj" -scheme "LED MESSENGER" -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' build
```

**Run Tests:**
```bash
xcodebuild -project "LED MESSENGER.xcodeproj" -scheme "LED MESSENGER" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

**Run Single Test:**
```bash
xcodebuild -project "LED MESSENGER.xcodeproj" -scheme "LED MESSENGER" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test -only-testing "LED_MESSENGERTests/SpecificTestClass/testMethodName"
```

## Project Architecture

### Core Architecture Pattern
- **MVVM with SwiftUI**: Model-View-ViewModel architecture using SwiftUI views and @Observable ViewModels
- **iOS 18 @Observable Framework**: Migrated from ObservableObject to @Observable for modern iOS 18 patterns
- **Device-Aware Design**: Uses DeviceEnvironment to provide device-specific configurations (iPhone vs iPad vs macOS)
- **Actor-Based Thread Safety**: AppSettings and services use private actors for safe concurrent access

### Key Components

#### Device Environment System
- **DeviceEnvironment**: Central device detection and capability management
- **DeviceType enum**: iPhone, iPad, macCatalyst, mac with device-specific defaults
- **NetworkSettings**: Device-appropriate networking configurations and timeouts

#### Core Services
- **OSCService**: UDP-based OSC (Open Sound Control) communication with Resolume Arena
- **AppSettings**: Thread-safe global configuration with JSON persistence and device-aware defaults
- **QueueManager**: Actor-based message queue management with async/await operations
- **SupabaseManager**: Authentication and cloud services integration

#### ViewModels (@Observable)
- **QueueViewModel**: Message queue management for solo mode operations
- **DashboardViewModel**: Main UI state management and modal coordination
- **AuthViewModel**: User authentication state and Supabase integration

#### Key Views
- **AuthenticatedView**: Main application container with device-adaptive routing
- **DashboardContainer**: Primary dashboard with message queue and controls
- **SettingsWizardView**: Multi-step configuration wizard (Connection → Clip → Text Format)
- **NewMessageModal**: Message creation with label management
- **Device-Specific Components**: iPhone/iPad optimized UI components in Views/Components/

### OSC Protocol Integration
- **Target**: Resolume Arena LED wall software communication
- **Protocol**: UDP-based OSC messages for text display control
- **Message Paths**: `/composition/layers/{layer}/clips/{clip}/connect` for triggering, `/composition/layers/{layer}/clips/{clip}/video/source/textgenerator/text/params/lines` for text content
- **Default Settings**: Layer 3, Clips 1-3, Port 2269 (note: Resolume typically uses 7000)

### Authentication & Cloud Features
- **Supabase Integration**: Full authentication flow with email/password and magic links
- **URL Scheme**: `ledmessenger://` for deep linking and password reset flows
- **Device-Specific Auth**: Tailored authentication UI and processing per device type

### Modern iOS 18 Patterns
- **@Observable Classes**: Replaced @ObservableObject with @Observable for ViewModels and services
- **Environment Injection**: `.environment(Type.self, instance)` pattern for dependency injection
- **Actor Isolation**: `@MainActor` for UI components, private actors for data services
- **Swift Concurrency**: Comprehensive async/await usage with proper task management

### Dependencies
- **Supabase Swift SDK**: Authentication, real-time, and cloud functions
- **Lottie**: Animation framework for splash screens and UI animations
- **Swift Package Manager**: Dependency management

### File Organization
```
LED MESSENGER/
├── Models/           # Data structures (Message, DeviceEnvironment)
├── Views/            # SwiftUI views organized by feature
├── ViewModels/       # @Observable business logic classes
├── Services/         # Core services (OSC, networking, queue management)
├── Utils/            # Extensions, error handling, logging
├── Auth/             # Authentication views and logic
└── Assets.xcassets/  # App icons, images, color sets
```

### Configuration & Settings
- **Info.plist Integration**: Network permissions, URL schemes, Bonjour services
- **Device-Specific Defaults**: Different OSC hosts and networking settings per device type
- **JSON Persistence**: AppSettings automatically persists configuration changes
- **Live Preview System**: Real-time LED wall text formatting simulation

### Development Notes
- **iOS 18.4+ Required**: Uses latest SwiftUI and @Observable framework features
- **Device Testing**: Test on both iPhone and iPad simulators due to different UI layouts
- **Network Testing**: OSC communication requires network access - test on physical devices for full networking
- **Thread Safety**: All UI updates must be on MainActor, background operations use proper actor isolation

## Code Style Guidelines

### Swift/SwiftUI Patterns
- **@Observable Usage**: Prefer @Observable over ObservableObject for new ViewModels
- **Actor Isolation**: Use `@MainActor` for UI-related classes, private actors for data services
- **Environment Injection**: Use `.environment(ObjectType.self, instance)` for dependency injection
- **State Management**: `@State` for local UI state, `@Observable` classes for shared business logic
- **Concurrency**: Always use `await` with actor methods, wrap UI updates in `Task { @MainActor in ... }`

### Device-Aware Development
- **DeviceEnvironment First**: Always check device capabilities before implementing features
- **Conditional UI**: Use device type checks for iPhone vs iPad specific layouts
- **Network Configuration**: Apply device-appropriate networking settings (timeouts, background modes)
- **Testing Strategy**: Test core functionality on both iPhone and iPad simulators

### OSC Protocol Guidelines
- **Message Timing**: Avoid rapid-fire OSC bursts - Resolume prefers consistent timing
- **Path Validation**: Validate OSC paths before sending to prevent Resolume crashes
- **Type Safety**: Use proper OSC types (int32, float32, string) for parameters
- **Error Recovery**: Implement retry logic for UDP transmission failures

### Architecture Best Practices
- **MVVM Separation**: Keep Views focused on UI, ViewModels handle business logic
- **Service Layer**: Abstract networking, persistence, and external APIs in dedicated services
- **Error Handling**: Use Result types and custom error enums for async operations
- **Logging**: Use OSLog for structured logging with appropriate categories