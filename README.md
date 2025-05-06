# 📱 Mangomolo iOS App

An iOS application built using Swift, SwiftUI, AVKit, and Google IMA SDK for streaming video content and dynamically serving ads. This project follows clean architecture principles and integrates UIKit with SwiftUI seamlessly.

---

## ✅ Features Implemented

### 🎬 HLS Video Playback
- Stream HLS video using `AVPlayer`
- Supports seeking, play, pause, and forward/rewind 15s
- Automatically resumes from last position
- Proper resource cleanup on exit
- Auto-resume playback and ad session when app returns from background

### 🛠 Custom Player Controls
- Play/Pause button with dynamic icon
- 15s skip forward/backward buttons
- Seek slider with current time and total duration
- Auto-hide controls with tap-to-show gesture
- Centered buffering indicator during delays

### 📺 Ad Integration (Google IMA SDK)
- Pre-roll, mid-roll, and post-roll ad support
- Seamless transitions between content and ads
- Ad container overlays `AVPlayer`
- Detects and resumes playback from correct position
- Disabled ads for subscribed users

### 🧭 Navigation and Presentation
- Full-screen player using SwiftUI `.fullScreenCover`
- Dismissal managed via `@Binding var isPresented`
- Prevents navigation conflicts using single navigation stack
- Portrait enforced by default, supports landscape during playback
- Orientation hint UI shown in portrait encouraging landscape for full-screen

### 🖼 Home Screen UI
- Two carousels:
  - Horizontal (landscape thumbnails)
  - Vertical (portrait thumbnails)
- Custom image assets: `robot_portrait` and `robot_landscape`
- Smooth horizontal scrolling with animations and corner radius
- Placeholder assets used — replace with production artwork

### 🔐 Subscription Management
- Toggle subscription state using a checkbox
- Subscription status saved to Keychain securely
- Ad logic controlled by subscription flag

### 🌙 Interface & Styling
- Forced dark mode across the app via Info.plist
- Matching full-screen layout with modern UI spacing
- Hides system navigation bar during playback

---

## 🧱 Technical Stack
- **Language:** Swift 5.10
- **UI:** SwiftUI + UIKit (UIViewControllerRepresentable)
- **Media:** AVPlayer + AVPlayerLayer
- **Ads:** Google IMA SDK (SPM)
- **Security:** Keychain
- **Architecture:** MVVM + Clean Architecture principles
- **Persistence:** UserDefaults (UI) + Keychain (secure flags)
- **Concurrency:** GCD (`DispatchQueue`)

---

## 🧪 Testing Notes
- Ad playback requires a real device (simulator won't trigger IMA ads)
- Test ad tag is hardcoded in `PlayerViewController.swift`
- Test orientation handling on both iPhone and iPad

---

## 🚀 Getting Started
1. Clone the repo:
```bash
git clone https://github.com/yourusername/mangomolo-ios.git
```
2. Open in Xcode:
```bash
open Mangomolo.xcodeproj
```
3. Install dependencies via Swift Package Manager (SPM)
4. Run on a real device for NFC and ad playback support

---

## 📩 Contact
**Johnny Owayed**  
johnny.owayed@gmail.com  
+961 71 213 231  
[LinkedIn](https://linkedin.com/in/johnnyowayed)

---

**Thank you for reviewing this project!**
