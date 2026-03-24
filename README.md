<div align="center">

# Course Tracker

An open-source Flutter application to track your progress through YouTube educational playlists and courses. 

<img src=".github/assets/playlist_screen.jpg" width="400"/>

</div>

# Course Tracker

Course Tracker is a privacy-first, fully local application that allows you to import YouTube playlists and track your learning progress. Instead of relying on YouTube's watch history which can get cluttered, Course Tracker gives you a dedicated space to manage your educational content.

<img src=".github/assets/progress_screen.jpg" width="400"/>

## Features

- **Progress Tracking**: See exactly how many videos you've completed and your percentage progress through a course.
- **Multiple Playlists**: Import and manage multiple courses simultaneously.
- **Offline Storage**: All your progress and data is stored locally on your device using Hive.
- **Deep Linking**: Tap any video to seamlessly open and watch it directly in the YouTube app.
- **Dark Mode**: Built-in support for system light/dark themes.
- **Custom API Keys**: Use your own YouTube Data API v3 key for importing playlists.

<br />

## Why use Course Tracker?

When learning from long YouTube courses (like 50+ video programming tutorials), it's easy to lose your place or forget which videos you've actually finished vs just clicked on. 

Course Tracker solves this by letting you explicitly mark videos as watched via a simple swipe gesture, completely independent of your YouTube account history.

<br />

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- A YouTube Data API v3 Key

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/course_tracker.git
cd course_tracker
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Setting up the API Key
When you first launch the app, click the 🔑 (key) icon in the top right corner and paste your YouTube Data API v3 key to enable playlist importing.

<br />

---

## Security

All your data (including your API key) is stored locally on your device. The app makes network requests directly to the YouTube API, with no intermediary servers.
