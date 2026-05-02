# 💜 Circle

> A private, couple-centric social app for managing shared memories, logistics, and communication.

Built with **Flutter** + **Supabase** | Zero-cost deployment | Privacy-first design

---

## 📖 What is Circle?

Circle is more than just a messaging app—it's a complete relationship management platform designed for couples. It combines:

- 💬 **Real-time Chat** with threaded conversations
- 📝 **Demand & Logistics Hub** for tracking needs and pickups
- 🖼️ **Memory Vault** for organizing shared photos
- 🎯 **Shared Dashboard** with milestones and quick actions
- 🔒 **Privacy-First** with biometric lock and end-to-end security

---

## ✨ Key Features

### 🏛️ Circles (Group Management)
- **Duo Space**: Your private, default space
- **Themed Groups**: Organize by topic (Travel, Wedding, etc.)
- **Member Roles**: Control who can manage content

### 💬 Social Chat
- Real-time messaging via WebSockets
- Threaded replies for organized conversations
- Media support (photos, voice notes, location)
- Custom status indicators ("At Uni", "Studying", etc.)

### 📝 Demand & Logistics Hub
- **Food Demand Feed**: Track cravings and requests
- **Pickup Tracker**: Priority-based to-do system
- **Smart Notifications**: Never miss an important item
- **Reactions**: Heart and comment on demands

### 🖼️ The Vault
- Chronological photo timeline
- Automatic image compression
- Metadata tagging (date, location, circle)
- Search and filter capabilities

### 🎨 User Experience
- Dark/Light mode with custom themes
- Shared dashboard with key metrics
- Biometric lock (fingerprint/FaceID)
- Milestone counter ("Days since/until")

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.7+ |
| **State Management** | Riverpod |
| **Backend** | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| **Local Storage** | Hive |
| **Authentication** | Supabase Auth + Biometric |
| **Real-time** | WebSockets (Supabase Realtime) |
| **Image Handling** | flutter_image_compress, cached_network_image |

---

## 📁 Project Documentation

This repository contains comprehensive planning documents (140 KB total) in the `docs/` folder:

**📑 [docs/INDEX.md](docs/INDEX.md) - Start here for complete documentation navigation**

| Document | Description | Size |
|----------|-------------|------|
| **[docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)** | Day 1 setup checklist and environment configuration | 10 KB |
| **[docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)** | Executive overview and project statistics | 13 KB |
| **[docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)** | Complete 11-week development roadmap with phases | 12 KB |
| **[docs/DEVELOPMENT_TIMELINE.md](docs/DEVELOPMENT_TIMELINE.md)** | Day-by-day development plan with milestones | 13 KB |
| **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** | System architecture, data flows, and diagrams | 39 KB |
| **[docs/FILE_STRUCTURE.md](docs/FILE_STRUCTURE.md)** | Complete project organization and naming conventions | 21 KB |
| **[docs/IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md)** | Step-by-step setup instructions and SQL schemas | 14 KB |
| **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** | Commands, snippets, and troubleshooting guide | 11 KB |

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.7+
- Dart 3.0+
- Supabase account (free tier)
- Android Studio or VS Code

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd circle
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a project at [supabase.com](https://supabase.com)
   - Run the SQL schema from [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
   - Copy your project URL and anon key

4. **Configure environment**
   - Update `lib/main.dart` with your Supabase credentials
   - Or create a `.env` file (recommended)

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📊 Development Phases

### ✅ Phase 1: Foundation (Week 1-2)
- Project setup and authentication
- User profile management
- Theme system

### 🔄 Phase 2: Circles & Chat (Week 3-4)
- Circle creation and management
- Real-time messaging
- Media upload

### 🔄 Phase 3: Demands & Logistics (Week 5-6)
- Demand feed and tracking
- Priority system
- Push notifications

### 🔄 Phase 4: The Vault (Week 7-8)
- Photo gallery with timeline
- Image compression and optimization
- Search and filtering

### 🔄 Phase 5: Dashboard & Polish (Week 9-10)
- Shared dashboard
- Milestone counter
- Performance optimization

### 🔄 Phase 6: Deployment (Week 11)
- APK generation
- Documentation
- Distribution

---

## 💰 Cost Breakdown

| Service | Free Tier | Usage |
|---------|-----------|-------|
| **Supabase Database** | 500MB | Text data |
| **Supabase Storage** | 1GB | Compressed images |
| **Supabase Bandwidth** | 2GB/month | API calls |
| **Supabase Realtime** | 200 concurrent | WebSockets |
| **Flutter** | Free | Development |
| **Distribution** | Free | APK/Web |

**Total Monthly Cost: $0** 🎉

---

## 🔒 Security Features

- **Row Level Security (RLS)**: Database-level access control
- **Biometric Authentication**: Fingerprint/FaceID app lock
- **Secure Storage**: Encrypted token storage
- **HTTPS Only**: All communications encrypted
- **Input Validation**: Protection against injection attacks

---

## 📱 Supported Platforms

| Platform | Status | Distribution |
|----------|--------|--------------|
| **Android** | ✅ Primary | Direct APK |
| **iOS** | ✅ Supported | Web/TestFlight |
| **Web** | ✅ Supported | Netlify/Vercel |
| **Desktop** | 🔄 Future | TBD |

---

## 🎯 Roadmap

### MVP (Current Focus)
- [x] Project planning and architecture
- [ ] Authentication system
- [ ] Real-time chat
- [ ] Demand tracking
- [ ] Photo vault
- [ ] Dashboard

### Post-MVP
- [ ] End-to-end encryption
- [ ] Video support
- [ ] Calendar integration
- [ ] Budget tracker
- [ ] Mood tracker
- [ ] Widget support
- [ ] Desktop apps

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### Web
```bash
flutter build web --release
```

---

## 🤝 Contributing

This is a private project, but if you're working on it:

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'feat: add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Review and merge

---

## 📝 License

This is a private project. All rights reserved.

---

## 🆘 Support

- **Documentation**: Check the docs folder
- **Issues**: Create an issue in this repository
- **Questions**: Refer to [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **Supabase Team**: For the generous free tier
- **Open Source Community**: For all the packages used

---

## 📸 Screenshots

_Coming soon after UI implementation_

---

## 🎉 Getting Started

Ready to build? Start with:

1. Read [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) for the complete roadmap
2. Follow [docs/IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md) for setup
3. Reference [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for technical details
4. Keep [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) handy during development

---

**Built with 💜 for private moments**
