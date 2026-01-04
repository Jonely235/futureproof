# FutureProof iOS App - Development Plan

## Project Overview

**App Name**: FutureProof (working title)
**Target Platform**: iOS (primary), Android (future)
**Goal**: Answer "Are we going to be okay?" for couples' financial planning
**Core Philosophy**: Reassurance over restriction, narrative over numbers

---

## Development Environment Setup (Windows)

### Current Reality
- **You're on Windows** → Cannot run Xcode natively
- **Need to publish to iOS App Store** → Requires macOS at some point
- **Solution**: Hybrid approach

### Recommended Setup

#### Option A: Cross-Platform with Cloud Build (Recommended for Windows)
```
Development Machine: Windows
├── Framework: Flutter (Dart)
├── IDE: VS Code or Android Studio
├── Testing: Android emulator + your physical iPhone (for preview)
└── iOS Build: GitHub Actions with macOS runner OR Codemagic (CI/CD)
```

**Pros**:
- Develop 100% on Windows
- Same codebase works on iOS + Android later
- Free CI/CD for iOS builds (GitHub Actions gives macOS runners free)

**Cons**:
- Flutter has learning curve
- iOS testing requires workarounds until build
- App doesn't feel 100% native (close though)

#### Option B: Remote Mac Development
```
Development Machine: Windows
├── Remote Mac: MacStadium, AWS, or Xcode Cloud
├── Connect via: Remote Desktop, VNC, or VS Code Remote SSH
└── Native Swift + SwiftUI development
```

**Cost**: ~$20-100/month depending on service

#### Option C: Buy a Used Mac (Best Long-Term)
- Mac Mini M1 (2020 or later) - ~$400-600
- Run macOS + Xcode natively
- Can dual-boot or use as dedicated build machine

---

## Phase 1: MVP Scope (6-8 weeks)

### Core Features
1. **"Are We Okay?" Button** - One tap financial health check
2. **Manual expense tracking** - Quick add expenses/income
3. **Simple budget categories** - Not complex, just basic buckets
4. **Basic analytics** - Spending trends, not over-budget alerts
5. **Local data storage** - No sync yet (you + girlfriend share one device initially)

### Non-Features (Deliberately Excluded)
- ❌ Bank API integration (MVP)
- ❌ Cloud sync (MVP)
- ❌ AI chat (MVP)
- ❌ Streaks/gamification
- ❌ Multi-device sync

### Why This MVP?
- Test if the core concept works
- Get feedback on the "narrative over numbers" approach
- Learn what features actually matter
- Ship to App Store quickly

---

## Phase 2: V1.0 (Add Sync + Sharing)

### New Features
1. **Cloud sync** (iCloud or Firebase)
2. **Multi-user sharing** - You + girlfriend see same data
3. **Bank integration** - Plaid API (US) or open banking (other regions)
4. **Widgets** - Home screen "Are We Okay?" status
5. **Basic notifications** - Weekly summary, not alerts

---

## Phase 3: V2.0 (AI + Advanced Features)

### New Features
1. **AI chat interface** - Natural language financial questions
2. **Scenario planning** - "What if we buy X?"
3. **Advanced analytics** - Predictive spending
4. **Goals tracking** - Savings targets with visual progress
5. **Export features** - Reports, data export

---

## Local LLM Integration for AI Suggestions

### Why Local LLM?

**Benefits:**
- ✅ **Privacy**: Financial data NEVER leaves the device
- ✅ **No API costs**: Free after initial setup
- ✅ **Offline capable**: Works without internet
- ✅ **Fast**: No network latency
- ✅ **No rate limits**: Use as much as you want
- ✅ **App Store friendly**: No external API dependencies to worry about

**Trade-offs:**
- ❌ Larger app size (model files: 100MB - 4GB depending on model)
- ❌ Requires newer devices (iPhone 12+ recommended)
- ❌ Less capable than GPT-4 (but good enough for this use case)
- ❌ Battery usage (but manageable with optimizations)

---

### Recommended Local LLM Options for iOS

#### Option 1: Llama 3.2 (3B parameters) - RECOMMENDED

```
Model: Llama-3.2-3B-Instruct
Size: ~2GB (quantized 4-bit)
RAM: ~3GB
Performance: Great for simple Q&A
Speed: Fast on iPhone 12+ (15-30 tokens/sec)
Platform: Supports Core ML via llama.cpp
```

**Why this model?**
- Meta's open-source LLM
- Excellent at following instructions
- Works well with quantization (compression)
- Strong reasoning for financial queries
- Good for on-device deployment

---

#### Option 2: Phi-3 Mini (3.8B parameters)

```
Model: Phi-3-mini-4k-instruct
Size: ~2.3GB (quantized 4-bit)
RAM: ~3.5GB
Performance: Very capable for size
Speed: Fast on newer iPhones
Platform: Microsoft, supports Core ML conversion
```

**Why this model?**
- Built by Microsoft for edge devices
- Excellent performance-to-size ratio
- Optimized for mobile
- Strong at following instructions

---

#### Option 3: Gemma 2 (2B parameters)

```
Model: gemma-2-2b-it
Size: ~1.5GB (quantized 4-bit)
RAM: ~2.5GB
Performance: Good for simple tasks
Speed: Very fast even on older devices
Platform: Google, supports mobile deployment
```

**Why this model?**
- Smallest model option
- Faster on older devices
- Good for simple queries
- Lower battery usage

---

### Architecture for Local LLM

```
┌─────────────────────────────────────────────┐
│          Flutter iOS App                    │
│                                              │
│  ┌─────────────────────────────────────┐   │
│  │  AI Service Layer                   │   │
│  │  - Prompt engineering               │   │
│  │  - Context management               │   │
│  │  - Response parsing                 │   │
│  └───────────┬─────────────────────────┘   │
│              │                             │
│              ▼                             │
│  ┌─────────────────────────────────────┐   │
│  │  Native iOS Plugin (Swift)          │   │
│  │  - Model loading                    │   │
│  │  - Inference engine                 │   │
│  │  - Memory management                │   │
│  └───────────┬─────────────────────────┘   │
│              │                             │
└──────────────┼─────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  Core ML / llama.cpp                        │
│  - Llama-3.2-3B model (quantized)           │
│  - Metal acceleration (GPU)                 │
│  - On-device inference                      │
└─────────────────────────────────────────────┘
```

---

### Implementation Strategy

#### Step 1: Choose Inference Engine

**Option A: llama.cpp (Recommended)**
- C++ library with Swift bindings
- Supports GGUF model format (quantized)
- Metal acceleration for GPU
- Battle-tested, widely used
- Easy to integrate via Swift package

**Option B: Core ML (Native Apple)**
- Apple's official ML framework
- Best performance on Apple Silicon
- Harder to convert models
- More complex integration

**Recommendation**: Start with llama.cpp, easier to implement

---

#### Step 2: Model Quantization

Convert model to 4-bit quantization for size reduction:

```bash
# Convert Llama 3.2 to GGUF format
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Download Llama 3.2 3B model
# (You'll need to accept Meta's license first)

# Convert to GGUF 4-bit quantization
./convert-hf-to-gguf.py Meta-Llama-3.2-3B/ \
  --outfile llama-3.2-3b-q4_k_m.gguf \
  --outtype q4_k_m

# Result: ~2GB model file
```

---

#### Step 3: Create Swift Plugin for Flutter

**File: ios/Runner/AIService.swift**

```swift
import Foundation
import llama_cpp

class AIService {
    private var model: OpaquePointer?
    private var context: OpaquePointer?

    // Initialize model (call once at app startup)
    func initializeModel() -> Bool {
        let modelPath = Bundle.main.path(forResource: "llama-3.2-3b-q4_k_m", ofType: "gguf")

        // Load model parameters
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 32 // Use GPU if available

        // Load model
        model = llama_load_model_from_file(modelPath, modelParams)

        guard model != nil else { return false }

        // Create context
        var contextParams = llama_context_default_params()
        contextParams.n_ctx = 2048 // Context window
        context = llama_new_context(model, contextParams)

        return context != nil
    }

    // Generate response
    func generateResponse(prompt: String, maxTokens: Int = 256) -> String {
        guard let context = context, let model = model else {
            return "Error: Model not initialized"
        }

        // Tokenize prompt
        let tokens = tokenize(prompt: prompt)

        // Batch evaluation
        var output = ""
        for i in 0..<maxTokens {
            llama_decode(context, tokens)

            // Sample next token
            let token = llama_sample_token(context)

            // Decode token to text
            if let text = llama_token_to_text(context, token) {
                output += text
            }

            // Check for end of response
            if token == llama_token_eos(context) {
                break
            }
        }

        return output
    }

    private func tokenize(prompt: String) -> [llama_token] {
        // Implementation depends on llama.cpp version
        // Returns array of token IDs
        return []
    }

    deinit {
        if let context = context { llama_free(context) }
        if let model = model { llama_free_model(model) }
    }
}
```

---

#### Step 4: Flutter Method Channel

**File: lib/services/ai_service.dart**

```dart
import 'package:flutter/services.dart';

class AIService {
  static const platform = MethodChannel('com.yourapp.futureproof/ai');

  Future<void> initializeModel() async {
    try {
      await platform.invokeMethod('initializeModel');
      print('Model initialized successfully');
    } catch (e) {
      print('Failed to initialize model: $e');
    }
  }

  Future<String> getSuggestion({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double savingsGoal,
    required List<Transaction> recentTransactions,
  }) async {
    final prompt = _buildPrompt(
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      savingsGoal: savingsGoal,
      recentTransactions: recentTransactions,
    );

    try {
      final response = await platform.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': 256,
      }) as String;
      return response;
    } catch (e) {
      return 'Sorry, I couldn\'t generate a suggestion right now.';
    }
  }

  String _buildPrompt({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double savingsGoal,
    required List<Transaction> recentTransactions,
  }) {
    final transactionsSummary = recentTransactions
        .take(10)
        .map((t) => '- ${t.category}: \$${t.amount.toStringAsFixed(2)}')
        .join('\n');

    return '''You are a helpful financial advisor for a couple tracking their finances.

Current situation:
- Monthly income: \$${monthlyIncome.toStringAsFixed(2)}
- Monthly expenses: \$${monthlyExpenses.toStringAsFixed(2)}
- Savings goal: \$${savingsGoal.toStringAsFixed(2)}

Recent transactions:
$transactionsSummary

Please provide a brief, friendly suggestion (1-2 sentences) about their financial health.
Be encouraging and practical. Don't use financial jargon.
If they're overspending, suggest one specific area to review.
If they're doing well, celebrate it.

Suggestion:''';
  }

  Future<String> askQuestion(String question) async {
    final prompt = '''You are a helpful financial advisor.

User question: $question

Please provide a clear, friendly answer in 2-3 sentences.
Use simple language. Avoid jargon.''';

    try {
      final response = await platform.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': 256,
      }) as String;
      return response;
    } catch (e) {
      return 'Sorry, I couldn\'t answer that question.';
    }
  }
}
```

---

### AI Features to Implement

#### 1. Smart "Are We Okay?" Message

Instead of hardcoded responses, use LLM:

```dart
// Before: Static message
if (remaining > 0) {
  return "You're on track! $${remaining} left.";
}

// After: AI-generated message
final suggestion = await aiService.getSuggestion(
  monthlyIncome: income,
  monthlyExpenses: expenses,
  savingsGoal: savings,
  recentTransactions: transactions,
);
// Returns: "Great job staying on track! You have $450 left. Maybe treat yourselves to a nice dinner this weekend?"
```

#### 2. Natural Language Q&A

```dart
// User asks: "Can we afford a new laptop?"
final answer = await aiService.askQuestion(
  "Can we afford a new laptop that costs $1200?"
);

// AI responds: "Based on your current spending, you could afford it in 3 months if you set aside $400/month. Or wait until your bonus in June."
```

#### 3. Spending Pattern Analysis

```dart
final insights = await aiService.getSuggestion(
  monthlyIncome: 5000,
  monthlyExpenses: 4200,
  savingsGoal: 1000,
  recentTransactions: transactions,
);

// AI might say: "I noticed dining out is your biggest expense this month ($450). If you cook at home 2 more times per week, you could save an extra $150/month."
```

---

### Prompt Engineering Strategy

#### System Prompt Template

```
You are a friendly, non-judgmental financial advisor for couples.

Guidelines:
- Be encouraging, never critical
- Use simple language (no financial jargon)
- Give specific, actionable advice
- Celebrate wins, not just problems
- Acknowledge that different people have different priorities
- Never give strict rules, always offer suggestions
- Keep responses to 1-3 sentences unless asked for more detail

Tone: Warm, supportive, practical
```

#### Few-Shot Examples

Include in prompt for better results:

```
Example 1:
Income: $5000, Expenses: $4200, Savings goal: $1000
Good response: "You're doing great! $800 left means you're on track for your vacation fund. Maybe put $500 toward savings and enjoy $300 for fun?"

Example 2:
Income: $4000, Expenses: $4300, Savings goal: $500
Good response: "You're $300 over this month. Dining out was higher than usual ($450). Consider cooking at home this weekend to get back on track."

Example 3:
Income: $6000, Expenses: $3500, Savings goal: $2000
Good response: "Excellent! You're saving $500/month more than planned. Could accelerate your house fund or boost retirement savings."
```

---

### Performance Optimization

#### 1. Model Loading Strategy

```dart
class AIService {
  bool _isModelLoaded = false;

  Future<void> ensureModelLoaded() async {
    if (_isModelLoaded) return;

    // Show loading indicator
    // Load model (this takes 2-5 seconds)
    await initializeModel();
    _isModelLoaded = true;
  }

  // Call this when app starts (in background)
  Future<void> preloadModel() async {
    // Don't block UI
    Future.delayed(Duration.zero, ensureModelLoaded);
  }
}
```

#### 2. Response Caching

```dart
class AIService {
  final Map<String, String> _responseCache = {};

  Future<String> getSuggestion(FinancialContext context) async {
    // Create cache key from context
    final cacheKey = context.toString();

    // Check cache
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }

    // Generate response
    final response = await _generateResponse(context);

    // Cache for 1 hour
    _responseCache[cacheKey] = response;
    _clearCacheAfter(Duration(hours: 1));

    return response;
  }
}
```

#### 3. Stream Responses (Better UX)

Instead of waiting for full response, show tokens as they generate:

```dart
Stream<String> generateResponseStream(String prompt) async* {
  final tokens = platform.invokeMethod('generateResponseStream', {'prompt': prompt});

  await for (final token in tokens) {
    yield token; // Stream each token as it arrives
  }
}

// Usage
generateResponseStream(prompt).listen((token) {
  // Update UI in real-time
  currentResponse += token;
  setState(() {});
});
```

---

### Fallback Strategy

What if device is too old or model fails to load?

```dart
class AIService {
  Future<String> getSuggestion(FinancialContext context) async {
    // Try local LLM first
    try {
      final response = await _getLocalSuggestion(context);
      return response;
    } catch (e) {
      // Fallback to rules-based
      return _getRuleBasedSuggestion(context);
    }
  }

  String _getRuleBasedSuggestion(FinancialContext context) {
    // Simple if-else logic
    final remaining = context.income - context.expenses;

    if (remaining > context.savingsGoal) {
      return "You're on track! \$${remaining.toStringAsFixed(0)} left for flexible spending.";
    } else if (remaining > 0) {
      return "Almost there! You have \$${remaining.toStringAsFixed(0)} left. Consider reviewing dining expenses.";
    } else {
      return "Over budget by \$${abs(remaining).toStringAsFixed(0)}. Hold off on non-essential spending this week.";
    }
  }
}
```

---

### Device Compatibility

**Minimum Requirements:**
- iPhone 12 or later (A14 Bionic chip)
- iOS 15+
- 3GB+ RAM available

**For older devices:**
- Use smaller model (Gemma 2B - 1.5GB)
- Or fall back to rules-based suggestions
- Graceful degradation

**Detect capability:**

```dart
class DeviceCapability {
  static Future<bool> canRunLocalLLM() async {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo();

    // Check model
    final model = iosInfo.model;
    if (model.contains('iPhone1') || // iPhone 12+
        model.contains('iPhone13') ||
        model.contains('iPhone14') ||
        model.contains('iPhone15')) {
      return true;
    }

    return false;
  }
}
```

---

### App Size Impact

| Component | Size |
|-----------|------|
| Flutter app (base) | ~20MB |
| Llama 3.2 3B (4-bit) | ~2GB |
| Total | ~2.02GB |

**Strategies to reduce size:**

1. **Download model on first launch**
   - App bundle: ~20MB
   - Model downloads in background after install
   - Show progress: "Downloading AI brain... 45%"

2. **Use smaller model**
   - Gemma 2B: ~1.5GB
   - Still capable for this use case

3. **Model quantization**
   - 4-bit: 2GB (good quality)
   - 3-bit: 1.5GB (lower quality)
   - Trade-off decision

4. **Model pruning (advanced)**
   - Remove unnecessary weights
   - Requires retraining

---

### Battery Optimization

Local LLM can drain battery. Mitigation strategies:

1. **Generate suggestions on-demand only**
   - Don't run inference automatically
   - User taps "Ask AI" button

2. **Use Neural Engine (ANE) instead of GPU**
   - More efficient for ML inference
   - Supported on A12+ chips

3. **Cache aggressively**
   - Don't regenerate same responses
   - Cache valid for 24 hours

4. **Background processing**
   - Generate daily summary once/day
   - Schedule during charging

5. **Power monitoring**

```swift
// Monitor battery impact
func generateResponse(prompt: String) -> String {
  // Start energy measurement
  let startEnergy = ProcessInfo.processInfo.thermalState

  // Generate response
  let response = generateResponseInternal(prompt: prompt)

  // Check if we should throttle
  let endEnergy = ProcessInfo.processInfo.thermalState
  if endEnergy == .serious {
    // Reduce model complexity or use cache
  }

  return response
}
```

---

### Testing Local LLM

#### Unit Tests

```dart
void main() {
  group('AIService', () {
    test('generates suggestion for healthy finances', () async {
      final response = await aiService.getSuggestion(
        monthlyIncome: 5000,
        monthlyExpenses: 3500,
        savingsGoal: 1000,
        recentTransactions: [],
      );

      expect(response, contains('on track'));
    });

    test('generates suggestion for overspending', () async {
      final response = await aiService.getSuggestion(
        monthlyIncome: 4000,
        monthlyExpenses: 4500,
        savingsGoal: 500,
        recentTransactions: [],
      );

      expect(response.toLowerCase(), contains(RegExp('over|review|caution')));
    });
  });
}
```

#### Manual Testing Checklist

- [ ] Model loads in <5 seconds on iPhone 12
- [ ] Generates response in <3 seconds
- [ ] Response is relevant and helpful
- [ ] No memory leaks after 100 queries
- [ ] Battery drain <5% for 20 queries
- [ ] Fallback works when model unavailable
- [ ] Offline mode works (airplane mode)

---

### Alternative: Hybrid Approach (Local + Cloud)

Best of both worlds:

```dart
class HybridAIService {
  Future<String> getSuggestion(FinancialContext context) async {
    // Try local first (fast, private)
    if (await _isLocalAvailable()) {
      return await _getLocalSuggestion(context);
    }

    // Fallback to cloud API (if user enabled)
    if (userSettings.allowCloudAI) {
      return await _getCloudSuggestion(context);
    }

    // Last resort: rules-based
    return _getRuleBasedSuggestion(context);
  }
}
```

**Benefits:**
- Fast local responses most of the time
- Cloud backup when needed
- User choice (privacy vs capability)
- Can charge premium for cloud GPT-4 access

---

### Cost Comparison

| Approach | First Year | Ongoing | Privacy | Speed |
|----------|-----------|---------|---------|-------|
| **Local LLM** | $0 (dev time only) | $0 | ✅ Perfect | Fast (2-3s) |
| **OpenAI API** | Free tier ~$50 | $0.01-0.03/1K tokens | ❌ Data sent to OpenAI | Fast (1-2s) |
| **Claude API** | ~$100 | $0.003/1K tokens | ❌ Data sent to Anthropic | Fast (1-2s) |
| **Custom API (hosted)** | ~$500 (GPU server) | $20-100/month | ✅ You control it | Medium (2-5s) |

**Recommendation**: Start with **local LLM** for MVP
- Zero ongoing costs
- Best privacy (selling point!)
- Works offline
- No API key management

---

### Implementation Timeline

**Week 1-2: Setup**
- [ ] Choose model (Llama 3.2 3B)
- [ ] Set up llama.cpp in Xcode
- [ ] Convert model to GGUF format
- [ ] Test model loading on device

**Week 3-4: Integration**
- [ ] Create Flutter method channel
- [ ] Implement basic inference
- [ ] Build prompt templates
- [ ] Add error handling + fallback

**Week 5-6: Optimization**
- [ ] Implement caching
- [ ] Add streaming responses
- [ ] Optimize for battery
- [ ] Test on multiple devices

**Week 7-8: Polish**
- [ ] Improve prompts with user testing
- [ ] Add natural language queries
- [ ] Test offline mode
- [ ] Documentation + deployment

---

### Summary: Local LLM Approach

**Do this if:**
- ✅ You value privacy (major selling point)
- ✅ You want zero ongoing costs
- ✅ Offline support is important
- ✅ You're okay with 2GB app size
- ✅ Your target users have iPhone 12+

**Don't do this if:**
- ❌ You need GPT-4 level intelligence
- ❌ Your users have older iPhones
- ❌ You need smallest possible app size
- ❌ You want fastest possible responses

**For your use case (couple finance app):**
- Local LLM is **perfect**
- Queries are simple (financial advice, not complex reasoning)
- Privacy is a huge plus for financial data
- Offline is nice for traveling
- Cost savings is significant

---

## Tech Stack Options

### Option 1: Flutter (Recommended for Windows Development)

```
Frontend: Flutter + Dart
├── UI: Flutter widgets (material + cupertino)
├── State Management: Riverpod or Bloc
├── Local Storage: Hive (NoSQL) or Drift (SQLite)
├── Cloud Sync: Firebase Firestore
└── Bank API: Plaid SDK (has Flutter support)

Build & Deploy:
├── CI/CD: GitHub Actions (macOS runner) or Codemagic
├── iOS Signing: Automated in CI/CD
└── App Store: Fastlane for deployment
```

**Learning Resources**:
- Flutter documentation: flutter.dev
- "Flutter in Action" (book)
- Firebase Flutter codelabs

---

### Option 2: React Native

```
Frontend: React Native + TypeScript
├── UI: React Native Paper or NativeBase
├── State Management: Zustand or Redux Toolkit
├── Local Storage: AsyncStorage or Realm
├── Cloud Sync: Firebase Firestore
└── Bank API: Plaid React Native SDK

Build & Deploy:
├── Expo (easiest for Windows)
└── EAS Build (cloud builds)
```

**Pros**: JavaScript might be familiar
**Cons**: Performance worse than Flutter, more janky on iOS

---

### Option 3: Native Swift (Best App, Hardest on Windows)

```
Frontend: SwiftUI + Swift
├── UI: SwiftUI (declarative, modern)
├── Architecture: MVVM or Clean Swift
├── Local Storage: SwiftData (iOS 17+) or Core Data
├── Cloud Sync: CloudKit (native) or Firebase
└── Bank API: Plaid (iOS SDK)

Build & Deploy:
├── Remote Mac: MacStadium/AWS/Xcode Cloud
└── Xcode: Required for final builds
```

**Pros**: Best performance, true native iOS feel
**Cons**: Cannot develop fully on Windows, need remote Mac

---

## Data Architecture (CloudKit vs Firebase)

### CloudKit (iCloud)

```
Pros:
✅ Native to iOS
✅ Free tier (1GB per user)
✅ Users already signed in (Apple ID)
✅ Great privacy
✅ Automatic sync

Cons:
❌ Hard to debug
❌ iOS only (Android migration = rewrite)
❌ Query limitations
❌ No real-time features (web dashboard later)
```

**Best for**: iOS-only apps, privacy-focused, simple data models

---

### Firebase Firestore

```
Pros:
✅ Real-time sync
✅ Cross-platform (iOS + Android + Web)
✅ Rich queries
✅ Easy authentication (Email, OAuth, Phone)
✅ Great free tier (1GB + 50K reads/day)

Cons:
❌ Not native (requires Firebase SDK)
❌ Google dependency
❌ Can get expensive at scale
```

**Best for**: Cross-platform apps, real-time features, complex queries

---

### Recommendation for MVP

**Start with Firebase Firestore**

Why?
1. Develop on Windows → Android emulator works great
2. Use GitHub Actions macOS runner for iOS builds
3. Same stack works when you add Android later
4. Easier than CloudKit for multi-user sharing
5. Can add web dashboard later (your girlfriend might prefer that!)

---

## Feature Specification (MVP)

### 1. "Are We Okay?" Button

**User Flow**:
```
1. User opens app
2. Sees large button: "Are We Okay?"
3. Taps button
4. App calculates: (income - expenses - savings goal buffer)
5. Displays result:
   - 🟢 Green: "You're on track! $X left for flexible spending."
   - 🟡 Yellow: "Caution. You have $X left until next income."
   - 🔴 Red: "Overbudget by $X. Review big spending this week."
```

**Calculation Logic**:
```
monthly_income = sum(all income sources this month)
monthly_expenses = sum(all expenses this month)
savings_buffer = monthly_income * 0.2 (configurable)
remaining = monthly_income - monthly_expenses - savings_buffer

if remaining > 0:
  status = GREEN
  message = f"You're on track! ${remaining} left for flexible spending."
elif remaining > -monthly_income * 0.1:
  status = YELLOW
  message = f"Caution. ${abs(remaining)} left until next income."
else:
  status = RED
  message = f"Overbudget by $${abs(remaining)}. Review big spending this week."
```

**UI Design**:
- Full-screen button (hard to miss)
- Haptic feedback on tap
- Result card with emoji + one sentence
- "View Details" button for breakdown (optional)

---

### 2. Quick Add Expense

**User Flow**:
```
1. User taps big "+" button on home screen
2. Shows: Amount input (numeric keypad)
3. Category dropdown (Groceries, Dining, Transport, etc.)
4. Note field (optional, e.g., "Whole Foods")
5. "Add" button
```

**Categories** (preset, non-editable for MVP):
- 🏠 Housing (Rent, utilities)
- 🛒 Groceries
- 🍽️ Dining Out
- 🚗 Transport (Gas, parking, public transit)
- 🎭 Entertainment
- 💊 Health (Medical, pharmacy)
- 🛍️ Shopping
- 📱 Subscriptions (Netflix, Spotify, etc.)
- 💸 Other

---

### 3. Simple Dashboard

**Shows**:
- Current month total expenses
- Current month income
- "Are We Okay?" status card (same as button)
- Last 5 transactions list
- Quick add button

**Not showing**:
- ❌ Per-category budgets (too complex for MVP)
- ❌ Charts/graphs (unnecessary complexity)
- ❌ Historical data (beyond current month)

---

### 4. Settings Screen

**Options**:
- Monthly income input
- Savings buffer percentage (default 20%)
- Data export (CSV)
- Theme toggle (light/dark)
- About/Help

---

## Data Model (Firebase/Firestore)

```json
{
  "users": {
    "user_id_1": {
      "email": "user@example.com",
      "name": "John Doe",
      "household_id": "household_123",
      "created_at": "2025-01-04T10:00:00Z"
    }
  },

  "households": {
    "household_123": {
      "name": "My Family",
      "members": ["user_id_1", "user_id_2"],
      "created_at": "2025-01-04T10:00:00Z"
    }
  },

  "transactions": {
    "transaction_id_1": {
      "household_id": "household_123",
      "amount": -45.67,
      "category": "dining",
      "note": "Lunch with coworkers",
      "date": "2025-01-04",
      "created_by": "user_id_1",
      "created_at": "2025-01-04T12:30:00Z"
    },
    "transaction_id_2": {
      "household_id": "household_123",
      "amount": 3000.00,
      "category": "income",
      "note": "Salary",
      "date": "2025-01-01",
      "created_by": "user_id_1",
      "created_at": "2025-01-01T09:00:00Z"
    }
  },

  "monthly_budgets": {
    "budget_2025_01": {
      "household_id": "household_123",
      "month": "2025-01",
      "income": 5000.00,
      "savings_buffer_percent": 20,
      "created_at": "2025-01-01T00:00:00Z"
    }
  }
}
```

**Key Design Decisions**:
- `household_id` enables shared finances between couples
- Negative amounts for expenses, positive for income
- Monthly budgets track income + savings goal
- Simple structure, easy to query

---

## Development Roadmap

### Week 1-2: Setup + Core Data Structure
- [ ] Set up Flutter project on Windows
- [ ] Configure Firebase project
- [ ] Implement data models (User, Household, Transaction)
- [ ] Set up Firebase Authentication (Email + Password)
- [ ] Set up Firestore database
- [ ] Create basic app navigation

### Week 3-4: Core Features
- [ ] Build "Are We Okay?" calculation logic
- [ ] Create home screen UI
- [ ] Implement "Add Expense" flow
- [ ] Build transaction list display
- [ ] Add settings screen
- [ ] Implement local caching (Hive or shared_preferences)

### Week 5-6: Polish + Testing
- [ ] Error handling (no internet, auth errors)
- [ ] Input validation (amounts, dates)
- [ ] Loading states
- [ ] Dark mode support
- [ ] Accessibility basics (screen reader, contrast)
- [ ] Test on physical iOS device (if available)

### Week 7-8: Deploy to App Store
- [ ] Set up Apple Developer account ($99/year)
- [ ] Create App Store Connect listing
- [ ] Configure app icons, splash screen
- [ ] Write app description, screenshots
- [ ] Set up GitHub Actions for iOS builds
- [ ] TestFlight beta testing
- [ ] Submit for App Store review

---

## CI/CD Setup (GitHub Actions)

### Workflow for iOS Builds

```yaml
# .github/workflows/ios.yml
name: Build iOS

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build iOS app (no codesign)
        run: flutter build ios --release --no-codesign

      - name: Upload build artifact
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/Runner.app
```

### For App Store Deployment

Use **Codemagic** or **Fastlane**:
- Free tier available
- Handles code signing
- Deploys directly to TestFlight/App Store
- Works with Flutter

---

## App Store Considerations

### Requirements
1. **Apple Developer Account** - $99/year
2. **App Review Guidelines** - Must comply:
   - No misleading claims
   - Privacy policy required
   - Financial apps need disclaimers (not financial advice)
   - No auto-renewable subscriptions without clear disclosure

### Metadata Needed
- **App Name**: FutureProof (or your final choice)
- **Subtitle**: "Financial peace for couples"
- **Description**: (draft needed)
- **Keywords**: finance, budget, couples, money, planning
- **Screenshots**: (5 required, iPhone sizes)
- **App Icon**: 1024x1024 PNG
- **Privacy Policy**: (host on GitHub Pages or similar)

### Approval Tips
- Emphasize "educational" not "financial advice"
- Clearly state what the app does
- Show how data is protected (Firebase security rules)
- Test thoroughly before submission (crashes = rejection)

---

## Costs Breakdown

### Required Costs
- Apple Developer Program: $99/year
- Domain name (optional): $10-15/year
- Hosting (privacy policy page): Free (GitHub Pages) or $5/month (Netlify)

### Optional Costs
- Firebase: Free tier up to certain limits
  - Firestore: 50K reads/day, 20K writes/day (free)
  - Authentication: 10K verifications/month (free)
  - Hosting: 10GB/month (free)
- CI/CD:
  - GitHub Actions: 2000 minutes/month free (public repos)
  - Codemagic: Free tier (500 builds/month)

### Estimated First Year: ~$115-200

---

## Privacy & Security

### Financial Data Protection

**Firebase Security Rules**:
```javascript
// Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only access their own household data
    match /households/{householdId} {
      allow read: if request.auth != null &&
                     request.auth.token.household_id == householdId;
      allow write: if false; // Prevent direct writes
    }

    match /transactions/{transactionId} {
      allow read: if request.auth != null &&
                     resource.data.household_id in
                     request.auth.token.household_ids;
      allow create: if request.auth != null &&
                     request.resource.data.household_id in
                     request.auth.token.household_ids;
      allow update, delete: if request.auth != null &&
                              request.auth.uid == resource.data.created_by;
    }
  }
}
```

**Best Practices**:
- ✅ Encrypt data in transit (HTTPS/TLS)
- ✅ Firebase Authentication required
- ✅ Server-side validation (never trust client)
- ✅ No sensitive data in local logs
- ✅ Clear privacy policy
- ❌ Don't store bank credentials (use Plaid for bank connections later)
- ❌ Don't sell data

---

## Success Metrics (Post-Launch)

### Week 1
- Downloads: >100 (friends + family)
- Retention: >50% Day 1 retention
- Crash rate: <1%

### Week 4
- Active users: >500
- Weekly retention: >30%
- Average sessions per user: >2/week
- Feature usage: "Are We Okay?" button used by >80% users

### Month 3
- Active users: >2000
- Monthly retention: >20%
- App Store rating: >4.0 stars
- User feedback: Iterate based on reviews

---

## Future Considerations

### Phase 4: Monetization (If Successful)
Options:
1. **Freemium**: Free core features, paid premium features
   - Premium: AI chat, advanced analytics, unlimited transactions
   - Price: $4.99/month or $39.99/year

2. **Subscription-based**: Free trial, then monthly
   - Trial: 14 days free
   - Price: $2.99/month

3. **Paid app**: One-time purchase
   - Price: $9.99 (harder to sell)

### Phase 5: Advanced Features
- **Bank integration**: Plaid SDK (US), open banking (EU/UK)
- **Investment tracking**: Link to brokerage accounts
- **Debt payoff planner**: Snowball/avalanche methods
- **Tax preparation export**: Export for TurboTax/etc.
- **Web dashboard**: Access from desktop
- **Apple Watch app**: Quick "Are We Okay?" check from wrist

---

## Learning Resources

### Flutter Development
- [Flutter Official Docs](https://flutter.dev/docs)
- [Flutter Fire (Firebase)](https://firebase.flutter.dev)
- [Flutter YouTube Channel](https://youtube.com/flutterdev)
- [Reso Coder (Tutorials)](https://resocoder.com)

### Firebase
- [Flutter Firebase Codelabs](https://firebase.google.com/codelabs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security)

### App Store
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Fastlane for iOS Deployment](https://fastlane.tools)

### UI/UX Inspiration
- [Dribbble - Finance App Designs](https://dribbble.com/tags/finance-app)
- [Mobbin - Mobile App Patterns](https://mobbin.com)

---

## Alternative: Easier Path

If all of this feels overwhelming, consider **No-Code Options**:

### Glide Apps (glideapps.com)
- Build from Google Sheets
- Publish to iOS + Android
- Limited customization but fast
- Cost: $25-99/month

### Adalo (adalo.com)
- Drag-and-drop app builder
- Publish to App Store
- More powerful than Glide
- Cost: $50-200/month

### Bubble (bubble.io)
- Web app (wrap with PWA for iOS)
- Most powerful no-code option
- Cost: Free-$112/month

**Trade-off**: Less control, higher monthly cost, faster to build

---

## Next Steps

### Immediate (This Week)
1. [ ] Decide on tech stack (Flutter recommended for Windows)
2. [ ] Install Flutter SDK on Windows
3. [ ] Create Firebase project
4. [ ] Design basic wireframes (pen + paper is fine)
5. [ ] Gather requirements from girlfriend (what does SHE want?)

### Short-term (Next 2 Weeks)
1. [ ] Build "Are We Okay?" button prototype
2. [ ] Test with 5 couples
3. [ ] Get feedback
4. [ ] Iterate on concept
5. [ ] Decide: build full MVP or pivot?

### Long-term (Next 2 Months)
1. [ ] Complete MVP
2. [ ] Beta test with 20-50 users
3. [ ] Submit to App Store
4. [ ] Launch + gather feedback
5. [ ] Plan V1.1 based on feedback

---

## Questions to Answer Before Starting

1. **Do you have access to ANY Mac?** (Borrowed, remote, friend's?)
   - Yes: Can go native Swift (better app)
   - No: Must use Flutter + CI/CD

2. **What's your coding experience?**
   - Beginner: Consider no-code (Glide/Adalo) first
   - Intermediate: Flutter is doable
   - Advanced: Native Swift if you can get Mac access

3. **What's your budget?**
   - $0: GitHub Actions free tier, borrow Mac for final builds
   - $100-500: Buy used Mac Mini
   - $500+: Mac mini M1 new + Apple Developer account

4. **Timeline?**
   - Need app in 1 month: No-code or Flutter MVP
   - 3+ months: Native Swift build

5. **Is your girlfriend onboard with testing?**
   - She's your primary user
   - Her feedback matters more than anything
   - Build what SHE needs, not what you think she needs

---

## Final Recommendation

### For Windows + iOS App Store + Quick MVP:

**Use Flutter + Firebase + GitHub Actions**

**Why**:
1. Develop 100% on Windows
2. Free CI/CD for iOS builds (GitHub Actions)
3. Cross-platform (Android later if you want)
4. Firebase handles backend + sync + auth
5. Large community, good documentation
6. Good enough performance for this use case

**Alternative if you can swing it**:
- Buy used Mac Mini (~$400)
- Use native SwiftUI + CloudKit
- Better user experience, simpler architecture

**Either way**: START SMALL. Build "Are We Okay?" button first, test it, see if it actually solves the problem.

---

## Last Piece of Advice

**The best app is the one that actually exists.**

Don't overplan. Don't overengineer. Don't try to build the perfect finance app.

Build the simplest thing that answers the question: "Are we going to be okay?"

Ship it. Get feedback. Iterate.

Your girlfriend doesn't need features. She needs reassurance.

**Build that.**

---

*Document created: January 4, 2025*
*Last updated: January 4, 2025*
