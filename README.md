# QuestLearn – Gamified Educational Mobile Application

**A cross-platform educational RPG that transforms traditional learning into an interactive, knowledge-based combat experience.**

QuestLearn is a gamified learning application developed as my Bachelor's thesis project at Eötvös Loránd University (ELTE), Faculty of Informatics.

The application combines educational quizzes with RPG mechanics, allowing users to learn and practice their own study materials through turn-based combat, character progression, and AI-powered question generation.

Instead of treating a mobile device as a distraction, QuestLearn turns it into an interactive learning environment.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Gameplay Mechanics](#gameplay-mechanics)
- [AI Integration](#ai-integration)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Database Design](#database-design)
- [Action Queue System](#action-queue-system)
- [User Interface](#user-interface)
- [Offline Support](#offline-support)
- [Testing](#testing)
- [Installation and Setup](#installation-and-setup)
- [Future Improvements](#future-improvements)
- [Author](#author)
- [Acknowledgements](#acknowledgements)

---

## Overview

The main objective of QuestLearn is to make learning more engaging by combining educational content with video game mechanics.

The application introduces a knowledge-based combat system where the player's answers directly influence the outcome of battles.

Correct answers damage enemies and increase the player's combo counter, while incorrect answers allow enemies to counterattack.

The application provides two main game modes:

### 1. Story Mode

A narrative-driven campaign inspired by the curriculum of a Computer Science BSc program.

- Each level represents a different academic subject or topic.
- Players progress through increasingly challenging encounters.
- Completing encounters rewards experience points (XP).
- Defeating enemies unlocks progression through the campaign.

### 2. Custom Mode

A flexible learning environment that allows users to create and practice their own quiz decks.

- Create custom quiz decks.
- Add different types of questions.
- Choose between public and private decks.
- Browse and play publicly available decks.
- Practice any subject using personalized learning materials.

This makes the application suitable not only for university students but also for anyone who wants to practice and reinforce knowledge in an interactive way.

---

## Key Features

### Gamified Learning System

- Knowledge-based RPG combat mechanics.
- Dynamic health and damage calculation.
- Combo-based attack progression.
- Character abilities with unique animations.
- Experience points and character leveling.
- Upgradeable character attributes.
- Story-driven academic progression.

### Quiz Management

The application supports four different question types:

| Question Type | Description |
|---|---|
| Multiple Choice | Select one correct answer from multiple options. |
| Multiple Select | Select multiple correct answers. |
| Matching | Match related items from two groups. |
| Short Answer | Enter a free-text answer. |

Question cards are stored independently within their parent quiz decks, allowing flexible content management.

### User Management

- User registration and authentication.
- Secure login through Firebase Authentication.
- Editable user profiles.
- Username and avatar management.
- Persistent player progression and statistics.

### AI-Powered Learning

- Automatically generated quiz decks.
- Topic-based question generation.
- Multiple question formats.
- Semantic evaluation of free-text answers.
- Acceptance of synonyms and semantically equivalent responses.

---

## Gameplay Mechanics

The core gameplay revolves around a turn-based combat system where knowledge determines the outcome of battles.

### Combo System

Every correct answer increases the player's combo counter.

As the combo grows, the player gains access to increasingly powerful attacks.

However, incorrect answers reset the combo and trigger an enemy counterattack.

The damage received depends on the current combo level, introducing a risk-reward mechanic:

**Higher combos provide stronger attacks but also increase the consequences of mistakes.**

### Combat System

The combat interface consists of three main sections:

1. **Battlefield:** Displays the player character, enemies, health bars, and character animations.
2. **Combo and Abilities:** Displays the current combo level and available attacks.
3. **Question Interface:** Dynamically renders the appropriate input interface based on the current question type.

### Character Progression

Players earn experience points by completing encounters.

The character progression system includes:

- Experience points (XP).
- Character levels.
- Upgradeable attributes.
- Character-specific abilities.
- Different damage and resistance calculations.

---

## AI Integration

QuestLearn integrates Google's Gemini Flash large language model to provide intelligent learning functionality.

The integration is implemented using the `google_generative_ai` package in Flutter.

### AI-Generated Questions

Users can specify a topic and the desired number of questions.

The AI generates a quiz deck containing different question types.

To ensure compatibility with the application's internal data structures, the model is instructed to return structured JSON responses using:

`responseMimeType: application/json`

The generated data follows the application's internal `QuizCard` model, allowing questions to be processed programmatically.

### Semantic Answer Evaluation

Traditional quiz systems often rely on exact string matching, which can incorrectly reject valid answers because of different wording.

QuestLearn addresses this limitation through AI-powered semantic evaluation.

For short-answer questions, a dedicated AI evaluation process receives:

- The original question.
- The expected answers.
- The user's submitted answer.

The model evaluates whether the submitted response is semantically correct.

This allows the application to recognize:
- Synonyms.
- Alternative expressions.
- Correct explanations using different wording.
- Minor typing mistakes.

### Error Handling

An additional response-cleaning mechanism removes unexpected Markdown formatting from AI-generated responses before JSON processing.

---

## Technology Stack

The application uses a cross-platform architecture built around Flutter and Google Firebase.

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile development |
| Dart | Main programming language |
| Flame Engine | 2D game engine and combat animations |
| Firebase Authentication | User authentication |
| Cloud Firestore | NoSQL cloud database |
| Google Gemini Flash | AI-powered question generation and answer evaluation |
| `google_generative_ai` | Gemini API integration |
| `flutter_test` | Automated unit testing |

### Flutter & Dart

Flutter was selected to maintain a single codebase for Android and iOS.

Its widget-based architecture also provides the flexibility required to implement the application's custom pixel-art interface.

### Flame Engine

Flame is responsible for the 2D game environment, including:

- Character rendering.
- Sprite animations.
- Enemy animations.
- Character movement.
- Combat visual effects.
- Animation synchronization.

---

## System Architecture

QuestLearn follows a client-server architecture based on the Backend-as-a-Service (BaaS) model.

Google Firebase provides the backend infrastructure without requiring a separately maintained application server.

The architecture consists of three main layers:

### 1. Presentation Layer

The Flutter mobile application.

Responsibilities:
- Rendering the user interface.
- Managing local application logic.
- Handling gameplay and combat calculations.
- Rendering animations through Flame.
- Managing navigation and user interactions.

### 2. Service Layer

The Firebase SDK acts as the communication layer between the mobile application and cloud infrastructure.

Responsibilities:
- Network communication.
- Authentication token management.
- Local data persistence.
- Offline caching.
- Cloud synchronization.

### 3. Data and Infrastructure Layer

Google Firebase provides the cloud infrastructure.

Services:
- Firebase Authentication for user identity management.
- Cloud Firestore for storing user profiles, quiz decks, question cards, and progression data.

Firestore's event-driven synchronization enables real-time updates across connected clients.

---

## Database Design

The application uses Cloud Firestore, a document-oriented NoSQL database.

The main data collections are:

### Users

`users/{uid}`

Stores user profile and progression information.

Main fields:

- `uid`
- `username`
- `email`
- `created_at`
- `level`
- `photo_url`
- `settings`
- `stats`
- `total_xp`

Authentication credentials are handled separately by Firebase Authentication.

### Quiz Decks

`decks/{deckId}`

Stores quiz deck metadata.

Main fields:

- `title`
- `owner_id`
- `description`
- `created_at`
- `is_public`
- `card_count`

### Question Cards

`decks/{deckId}/cards/{cardId}`

Question cards are stored in subcollections rather than directly inside deck documents.

This design provides several advantages:

- Avoids large document sizes.
- Supports decks containing many questions.
- Allows question data to be loaded only when required.
- Provides a flexible structure for different question types.

The card data model is polymorphic, with its structure determined by the `type` field.

Supported types:

- `multiple_choice`
- `multiple_select`
- `matching`
- `short_answer`

### Security

The application uses Firebase's built-in security infrastructure.

The security design includes:

- Firebase Authentication-based identity verification.
- User ownership validation.
- Public and private deck access separation.
- Owner-only deck modification.
- Firestore security rules for validating database operations.
- Data type and schema validation.

---

## Action Queue System

One of the most technically challenging parts of the project was synchronizing combat logic with visual animations.

Initially, combat sequences relied on fixed asynchronous delays.

However, this approach introduced several problems:

- Animation timing inconsistencies.
- Frame-rate-dependent visual glitches.
- Interrupted animation sequences.
- Difficult-to-maintain nested callbacks.

To solve these issues, I designed and implemented a custom **event-driven Action Queue system**, based on the Command Pattern.

### Architecture

The system uses independent action objects implementing a shared interface with three main methods:

- `start()`
- `update()`
- `isDone()`

The queue executes actions sequentially, starting the next action only after the current one has actually completed.

### Implemented Action Types

| Action | Responsibility |
|---|---|
| `MoveAction` | Moves a character toward a target position. |
| `PlayAnimationAction` | Plays an animation and waits for its actual completion event. |
| `CallbackAction` | Executes custom logic, such as damage calculation or character state changes. |
| `DelayAction` | Introduces explicit pauses between actions. |

### Animation Synchronization

Instead of relying on estimated animation durations, `PlayAnimationAction` uses Flame's built-in animation ticker system and completion callbacks.

This ensures that gameplay events occur in synchronization with the actual visual animation state.

### Benefits

- Deterministic sequential action execution.
- Prevention of overlapping animations.
- Reliable interruption handling.
- Improved code readability and maintainability.
- Easier implementation of new character abilities.
- Consistent synchronization between gameplay logic and visual feedback.

The queue can also be cleared when a combat sequence is interrupted, allowing the system to transition safely into a new state.

This architecture was additionally validated through automated unit tests using mocked action objects.

---

## User Interface

The application features a custom dark-themed fantasy RPG interface inspired by classic pixel-art games.

The final design uses a dark purple color palette to create a consistent visual identity.

The main navigation contains four sections:

| Section | Functionality |
|---|---|
| PLAY | Access Story Mode and AI-powered practice. |
| LIB | Browse public and personal quiz decks. |
| NEW | Create and manage custom quiz decks. |
| HERO | View character progression, XP, and attributes. |

### Gameplay Interface

The combat screen is divided into three sections:

- Upper section: Character sprites, enemy sprites, animations, and health bars.
- Middle section: Combo counter and available abilities.
- Lower section: Dynamic quiz interface.

Each question type has its own dedicated interaction layout.

---

## Offline Support

QuestLearn supports offline gameplay through Firestore's local caching and persistence capabilities.

Users can play:

- Previously downloaded quiz decks.
- Story Mode content.

An active internet connection is required for:

- Initial account registration.
- First login.
- Creating or editing public quiz decks.
- AI-powered question generation and evaluation.

When connectivity is restored, locally cached data and player progression are synchronized with the cloud.

---

## Testing

The application was tested using both manual and automated testing methods.

### Testing Environments

**Emulators and Simulators**
- Android Studio emulators with different screen sizes.
- Xcode iOS Simulator.

**Physical Devices**
- Samsung Galaxy S10+.
- iPhone 14 Pro.

### Manual Testing

Functional and integration testing covered the main user workflows:

- Registration and authentication.
- Quiz deck creation and management.
- Gameplay and combat progression.
- Offline gameplay.
- Firebase communication.
- AI-based semantic answer evaluation.

User acceptance testing was also conducted with university students to gather feedback about interface usability and gameplay mechanics.

### Automated Unit Testing

Automated tests were implemented using Flutter's `flutter_test` package.

The tests cover four main architectural areas:

1. **Data Processing:** Validation of polymorphic quiz card models and handling of missing fields using mocked Firebase data.
2. **Combat Calculations:** Validation of character attributes, damage formulas, armor, and resistance calculations.
3. **CombatController:** Testing combat phases, healing restrictions, and turn-based buffs and debuffs.
4. **Action Queue:** Verification of sequential action execution and reliable queue management using mocked actions.

### Test Results

All documented functional test cases passed successfully.

The testing process also helped identify and resolve early UI alignment and state management issues.

---

## Installation and Setup

QuestLearn is designed to run on both Android and iOS devices.

### Prerequisites

- Flutter SDK.
- Dart SDK.
- Android Studio or Xcode.
- A configured Firebase project.
- Gemini API access for AI-powered functionality.

### 1. Clone the Repository

```bash
git clone https://github.com/LeventeForro/bsc-thesis.git

cd bsc-thesis
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Connect the application to your own Firebase project.

Configure the platform-specific Firebase configuration files and enable:

- Firebase Authentication.
- Cloud Firestore.

Make sure the required Firebase configuration files are available locally before running the application.

### 4. Configure Gemini API

Configure Gemini API access for the AI-powered functionality.

Do not commit API keys, credentials, or other sensitive configuration values to the repository.

### 5. Run the Application

```bash
flutter run
```

### 6. Run Automated Tests

```bash
flutter test
```

**Note:** The exact dependency versions and project-specific configuration requirements are defined by the application's source files. The repository owner should provide the necessary Firebase and AI configuration separately.

### Platform Availability

**Android:** The application can be installed using an APK build.

**iOS:** The application requires macOS and Xcode for building and installation on a development-provisioned device. It is not currently distributed through the Apple App Store.

---

## Future Improvements

Several improvements could further expand the application's functionality:

- **Social Features:** Friend system, shared private decks, leaderboards, and cooperative boss battles.
- **Advanced AI Personalization:** Learning progress analysis and automatically generated personalized study plans.
- **Audio Effects:** Sound effects for attacks, abilities, and combat interactions.
- **Equipment System:** In-game shop, loot mechanics, and character equipment.
- **Localization:** Support for multiple languages.
- **Multiplayer / PvP:** Competitive battles between players with global ranking points.

These features represent potential future development directions rather than currently implemented functionality.

---

## Author

**Levente Forró**

Bachelor of Science in Computer Science  
Eötvös Loránd University (ELTE)  
Faculty of Informatics

**Project:** Gamified Educational Mobile Application  
**Project Type:** Bachelor's Thesis  
**Year:** 2026

---

## Acknowledgements

Special thanks to the creators of the third-party pixel-art assets used in the application.

**Luiz Melo**
- [Monsters & Creatures Fantasy](https://luizmelo.itch.io/monsters-creatures-fantasy)

**OcO**
- [Asset Packs](https://itch.io/queue/c/844603/asset-packs)

Character sprites and animations are based on assets from these creators. Please refer to their respective licensing terms.

---

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flame Engine Documentation](https://docs.flame-engine.org/latest/flame/flame.html)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
