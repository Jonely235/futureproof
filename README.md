# FutureProof - iOS Finance App

> "The finance app that answers 'are we going to be okay?' so you don't have to."

## Project Overview

FutureProof is a personal finance app designed for couples who want to stop fighting about money and start feeling secure. Instead of complex budgets and scary spreadsheets, it provides simple, AI-powered answers to the questions that actually matter.

### Core Philosophy

**Reassurance over restriction. Narrative over numbers.**

Your girlfriend doesn't want a budget. She wants to know: "Are we going to be okay?"

This app answers that question.

---

## Key Features

### MVP (Phase 1)
- ✅ "Are We Okay?" button - One tap financial health check
- ✅ Quick expense tracking - Add expenses in 3 seconds
- ✅ Simple dashboard - See what matters at a glance
- ✅ Local data storage - Privacy first

### V1.0 (Phase 2)
- 🔲 Cloud sync via Firebase - Share finances between devices
- 🔲 Multi-user support - You + girlfriend see same data
- 🔲 Bank integration - Automatic transaction import
- 🔲 iOS widgets - Check status from home screen

### V2.0 (Phase 3)
- 🔲 Local AI suggestions - Powered by on-device LLM
- 🔲 Natural language Q&A - "Can we afford a new laptop?"
- 🔲 Scenario planning - "What if we buy X?"
- 🔲 Spending insights - AI-powered pattern recognition

---

## Tech Stack

### Frontend
- **Flutter** (Dart) - Cross-platform development
- **SwiftUI** (optional) - Native iOS alternative

### Backend
- **Firebase Firestore** - Cloud database & sync
- **Firebase Auth** - User authentication
- **Plaid API** (future) - Bank integration

### AI
- **Local LLM** (Llama 3.2 3B) - On-device AI suggestions
- **llama.cpp** - Inference engine
- **Core ML** - Hardware acceleration

---

## Folder Structure

```
FutureProof/
├── README.md                    # This file
├── DEVELOPMENT_PLAN.md          # Detailed development plan
├── docs/                        # Additional documentation (future)
│   ├── DESIGN.md               # UI/UX specifications
│   ├── API.md                  # API documentation
│   └── PROMPTS.md              # AI prompt templates
├── lib/                         # Flutter/Dart code (future)
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   └── services/
├── ios/                         # Native iOS code (future)
│   └── Runner/
│       └── AIService.swift     # LLM integration
└── test/                        # Tests (future)
```

---

## Development Environment

### Requirements
- **Flutter SDK** 3.16+ (for development on Windows)
- **Xcode** 15+ (for iOS builds - requires Mac or CI/CD)
- **Firebase project** (free tier)
- **iOS device** or simulator for testing

### Setup (Windows Development)

1. **Install Flutter**
   ```bash
   # Download from https://flutter.dev
   # Add to PATH
   flutter doctor
   ```

2. **Create Firebase project**
   - Go to https://firebase.google.com
   - Create new project
   - Enable Firestore and Authentication
   - Download GoogleService-Info.plist

3. **Clone this project** (when code is ready)
   ```bash
   git clone https://github.com/yourusername/futureproof.git
   cd futureproof
   flutter pub get
   ```

---

## Local LLM Setup

### Why Local LLM?

- ✅ **Privacy**: Financial data never leaves device
- ✅ **Free**: No API costs
- ✅ **Offline**: Works without internet
- ✅ **Fast**: No network latency

### Model Options

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| Llama 3.2 3B | 2GB | Fast (15-30 tok/s) | Great |
| Phi-3 Mini | 2.3GB | Fast | Very Good |
| Gemma 2B | 1.5GB | Very Fast | Good |

### Quick Start

```bash
# Install llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Download Llama 3.2 3B (requires Meta account approval)
# Then convert to GGUF format
./convert-hf-to-gguf.py Meta-Llama-3.2-3B/ \
  --outfile llama-3.2-3b-q4_k_m.gguf \
  --outtype q4_k_m
```

See [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md#local-llm-integration) for detailed instructions.

---

## Roadmap

### Current Status: Planning Phase

- [x] First-principles analysis
- [x] Feature specification
- [x] Tech stack selection
- [x] Development plan created
- [ ] Set up Flutter project
- [ ] Design UI mockups
- [ ] Implement MVP
- [ ] Test with users
- [ ] Submit to App Store

### Timeline

| Phase | Duration | Target |
|-------|----------|--------|
| MVP | 6-8 weeks | Core features |
| V1.0 | +4 weeks | Sync + sharing |
| V2.0 | +6 weeks | AI + advanced |

---

## Getting Started

### For Development

1. Read the **[DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md)** - Everything you need to know
2. Set up your development environment (Flutter + Firebase)
3. Build MVP first - "Are We Okay?" button + expense tracking
4. Test with 5-10 couples
5. Iterate based on feedback

### For Deployment

**iOS App Store Requirements:**
- Apple Developer Account ($99/year)
- Mac or cloud Mac for builds (GitHub Actions, MacStadium, etc.)
- App Store Connect listing
- Privacy policy
- Comply with review guidelines

**Estimated First Year Cost:** ~$115-200

---

## Frequently Asked Questions

### Q: Can I develop this on Windows?

**A:** Yes! Use Flutter for development, then:
- Use GitHub Actions (macOS runner) for iOS builds - **FREE**
- Or use Codemagic CI/CD
- Or borrow a Mac for final builds
- Best option: Buy used Mac Mini (~$400) for full control

### Q: Do I need to know Swift?

**A:** Not for Flutter development. But you'll need Swift knowledge for:
- Local LLM integration (llama.cpp)
- Native iOS features
- Better performance

**Recommendation:** Learn basics of Swift, but Flutter is sufficient for MVP

### Q: Is local LLM good enough?

**A:** For this use case, YES:
- Financial advice is simple (not complex reasoning)
- Llama 3.2 3B is surprisingly capable
- Privacy > GPT-4 for financial data
- Zero ongoing costs vs API bills

### Q: What if my girlfriend's iPhone is too old?

**A:** Fallback strategy:
- Detect device capability
- Use rules-based suggestions for older devices
- Or use smaller model (Gemma 2B)
- Graceful degradation

### Q: How do I make money from this?

**A:** Options (after you have users):
1. **Freemium**: Free core, paid AI/features
2. **Subscription**: $2.99-4.99/month
3. **Paid app**: $9.99 one-time
4. **B2B**: White-label for financial advisors

**Focus on building value first, monetize later.**

---

## Resources

### Learning Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Codelabs](https://firebase.google.com/codelabs)
- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [Llama Models](https://llama.meta.com/)

### Inspiration
- [Dribbble - Finance App Designs](https://dribbble.com/tags/finance-app)
- [Mobbin - Mobile App Patterns](https://mobbin.com)
- [App Store - Top Finance Apps](https://apps.apple.com/us/finance/)

---

## Contributing

Currently in early development. Not accepting contributions yet, but feel free to:
- Fork this project
- Build your own version
- Share learnings

---

## License

TBD - Will decide before public release.

---

## Contact

Questions? Ideas? Want to collaborate?

Open an issue on GitHub or reach out directly.

---

## Acknowledgments

- Built with ❤️ for couples who want to feel secure about their finances
- Inspired by real conversations (and real questions)
- First-principles thinking by [first-principles skill](https://github.com/anthropics/claude-code)

---

**Last Updated**: January 4, 2025

*Note: This is a planning document. Actual implementation may change based on user feedback and technical constraints.*
