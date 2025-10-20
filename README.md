# Kaiteki Voice Assistant

Kaiteki is a voice-powered onboarding and assistant experience for a digital wellbeing application.  
This Flutter-based project demonstrates how to build a conversational AI that guides users through setup, collects information, and updates their profiles using natural language.

The assistant leverages OpenAI's GPT models for understanding and responding to user input and uses secure local device storage to persist user data.

---

## Project Description

The goal of this project is to create a frictionless and accessible onboarding process for the Kaiteki app, designed to promote digital wellbeing.  

The voice assistant helps users (both parents and children) set up their profiles by asking a series of conversational questions.  
Once onboarding is complete, the assistant remains available to help users update their information—such as changing their name, phone number, or content filter settings—through simple voice commands.

---

## Features

- **Voice-Driven Onboarding:** Conversational flow to collect user details such as name, phone number, role (parent/child), and wellbeing preferences.  
- **Natural Language Understanding:** Uses OpenAI GPT-4o-mini to interpret user input and modify stored profile data.  
- **Text-to-Speech (TTS) and Speech-to-Text (STT):** Provides a hands-free experience using the device’s microphone and speaker.  
- **Persistent Local Storage:** Securely stores user data and chat history with `flutter_secure_storage`.  
- **Dynamic User Flows:** Distinct onboarding experiences for parent and child roles.  
- **Conversational Profile Updates:** Users can update information through natural voice commands (e.g., “Change my name to John”).  

---


### Project Structure 

| Path / File | Description |
| :-- | :-- |
| `android/` | Android-specific files |
| `ios/` | iOS-specific files |
| `lib/` | Main Dart source code |
|   └─ `main.dart` | App entry point |
|   └─ `voice_onboarding.dart` | Voice onboarding UI and logic |
|   └─ `gpt_assistant_page.dart` | Main assistant interface |
|   └─ `gpt_service.dart` | Handles OpenAI API communication |
|   └─ `intent_service.dart` | Processes intents from AI responses |
|   └─ `storage_service.dart` | Secure local storage management |
|   └─ `log_service.dart` | Logging utility |
| `pubspec.yaml` | Dependencies and metadata |
| `README.md` | This file |


***



## Tech Stack and Dependencies

**Framework:** Flutter  
**AI Service:** OpenAI API (gpt-4o-mini)  
**State Management:** StatefulWidget  

### Core Packages

- `speech_to_text` – Converts voice to text  
- `flutter_tts` – Converts text to voice  
- `http` – Handles API calls to OpenAI  
- `permission_handler` – Requests microphone permissions  
- `flutter_secure_storage` – Provides secure local data storage  
- `shared_preferences` – Manages non-sensitive user preferences  

---

## Software Prerequisites

Before setting up, ensure the following are installed:

- **Flutter SDK** version 3.8.1 or higher  
- **Dart SDK** version 3.8.1 or higher  
- **Code Editor:** Visual Studio Code, Android Studio, or IntelliJ IDEA with the Flutter plugin  

**For mobile development:**
- **iOS:** Xcode and CocoaPods  
- **Android:** Android Studio and Android SDK  
- **API Key:** A valid OpenAI API key  

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Daksh12207/kaiteki-onboarding-AI.git
cd kaiteki-onboarding-AI
```


### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Key

Create a new file for your API key:

```bash
lib/api_key.dart
```

Add your key inside the file:

```bash
// lib/api_key.dart
const String openAIAPIKey = "YOUR_OPENAI_API_KEY";
```

Update Source Files:
- Add import 'api_key.dart'; at the top of lib/gpt_service.dart
- Update any hardcoded API key usage to reference openAIAPIKey
- Ensure GPTService() uses the constant internally

Ignore Sensitive Files:

Add this to .gitignore:
# API Keys
```bash
lib/api_key.dart
```

### 4. Configure Platform Permissions

For iOS (ios/Runner/Info.plist):
```bash
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app requires speech recognition to function.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to listen to your voice commands.</string>
```

For Android (android/app/src/main/AndroidManifest.xml):
```bash
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Running the Application

Connect a device or start an emulator, then run:
```bash
flutter run
```

### Usage:
- Initial Screen: The app asks if you’d like to enable a voice-based experience.
- Voice Selection: Choose an available assistant voice, with preview options.
- Onboarding: The assistant guides you through setting up your profile. Speak your responses when prompted.
- Assistant Page: After onboarding, you can interact naturally (e.g., “Update my screen time to 2 hours”).
- Chat History: Your previous conversations are displayed in the assistant interface.

### Future Enhancements:
- Add cloud-based profile synchronization
- Support multiple languages and accents
- Integrate emotion-aware conversational responses
- Implement adaptive onboarding using real-time sentiment analysis

### License

This project is licensed under the MIT License.

### Developed using Flutter and OpenAI technologies.


