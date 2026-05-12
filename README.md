# Earth Science Gamified Mobile App

A production-ready Flutter mobile application designed for Earth Science instruction, gamified learning, and research-driven evaluation using the Rapid Application Development (RAD) model.

## Core Goals

- Improve student engagement through gamification (XP, streaks, badges, challenges)
- Improve vocabulary mastery and conceptual understanding in Earth Science
- Provide competency-focused lessons and quizzes
- Support teacher-side lesson management and lesson exemplar workflows
- Support alpha/beta testing data capture via in-app evaluation forms

## Tech Stack

- Flutter
- Riverpod (state management)
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- GoRouter (routing)

## Roles

- Student
- Teacher

## Main Features

### Student

- Splash + onboarding
- Email/password + Google sign-in + forgot password
- Gamified dashboard (XP, level, streak, progress snapshots)
- Lesson list, filter, search, lesson details
- Interactive quiz flow with timer and immediate feedback
- Quiz results with celebratory confetti for strong performance
- Challenges, achievements, progress analytics, profile

### Teacher

- Teacher dashboard
- Manage lessons (create/edit/delete)
- Manage quizzes (create/edit/delete)
- Student monitoring snapshots (score, vocabulary, conceptual, engagement)
- Lesson exemplars module (create/edit/delete)

### Research/Evaluation

- Evaluation module for alpha/beta data gathering
- Ratings for engagement, functionality, aesthetics, information, perceived impact
- Comment capture and test type tagging

## RAD Model Mapping

- Phase I: Requirements Planning
  - instructional/technical requirements translated into feature requirements
- Phase II: User Design / Prototyping
  - reusable widgets, modular screens, role-based UX flow
- Phase III: Construction
  - feature-based clean architecture + Firebase data layer + Riverpod state
- Phase IV: Cutover / Testing & Implementation
  - analyzer-clean code, widget tests, and evaluation module for field testing

## Firestore Collections

- `users`
- `lessons`
- `quizzes`
- `progress`
- `challenges`
- `achievements`
- `lesson_exemplars`
- `feedback_or_evaluation`

## Project Structure

```text
lib/
  core/
    constants/
    routes/
    services/
    theme/
    utils/
  shared/
    animations/
    dialogs/
    widgets/
  features/
    achievements/
    auth/
    challenges/
    evaluation/
    home/
    lessons/
    onboarding/
    profile/
    progress/
    quiz/
    splash/
    teacher/
  app.dart
  main.dart
```

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Configure Firebase for Android and iOS:
   ```bash
   flutterfire configure
   ```
3. Ensure platform Firebase files are added (`google-services.json`, `GoogleService-Info.plist`).
4. Run app:
   ```bash
   flutter run
   ```

## Verification

- Static analysis: `flutter analyze` (no issues)
- Widget tests: `flutter test` (all tests passed)

## Notes

- The app includes local fallback data paths so UI and flows remain testable when Firebase is not yet configured.
- For deployment, complete Firebase setup and replace seeded content with production content pipelines.
