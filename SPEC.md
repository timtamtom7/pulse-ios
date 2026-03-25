# Pulse — Emotional Insight Engine

## 1. Concept & Vision

**Pulse** is your private emotional intelligence companion. It reads the quiet signals in your daily life — photos, voice notes, calendar patterns, journal entries — and surfaces patterns about your emotional world. When are you happiest? Most anxious? Most energized? It answers without ever leaving your device.

**Privacy is the product.** No cloud, no servers, no data harvesting. Everything lives on your phone, encrypted at rest. If you opt into sync, it's end-to-end encrypted via CloudKit. Pulse is built for people who want insight without surveillance.

The experience feels like a personal diary that breathes — warm, unhurried, gentle. It's not another productivity tool. It's a space that understands you.

---

## 2. Design Language

### Aesthetic Direction
Inspired by the warmth of analog journals and the softness of morning light. Think: a well-loved Moleskine meets a minimalist wellness app. Nothing clinical. Nothing performative.

### Color Palette
| Name | Hex | Usage |
|---|---|---|
| Cream | `#FDF8F3` | Primary background |
| Warm White | `#FFFFFF` | Cards, surfaces |
| Soft Blush | `#F5E6E0` | Secondary surfaces, hover states |
| Muted Rose | `#C4706A` | Primary accent, CTAs |
| Dusty Rose | `#A35D54` | Secondary accent, active states |
| Deep Ember | `#7A3E38` | Text emphasis, strong contrast |
| Warm Gray | `#8B7B74` | Secondary text |
| Charcoal | `#3D3531` | Primary text |
| Calm Sage | `#9CAF88` | Positive emotions, energy |
| Gentle Gold | `#D4A853` | Highlights, insights |

### Typography
- **Display:** System serif (New York) — insight cards, emotional labels
- **Body:** System sans (SF Pro) — all body copy, UI text
- **Mono:** SF Mono — timestamps, data labels

### Spatial System
- Base unit: 8pt
- Card padding: 24pt
- Section spacing: 32pt
- Screen margins: 20pt
- Corner radius: 16pt (cards), 12pt (buttons), 8pt (small elements)

### Motion Philosophy
Slow, intentional, breathing. Animations are 400-600ms with ease-in-out curves. Nothing snaps. Elements fade and drift into place like turning a page. Loading states use gentle pulse animations. Nothing jarring.

### Visual Assets
- SF Symbols exclusively (rounded variants preferred)
- No stock photos — abstract gradient blobs for empty states
- Custom emotional gradient overlays for timeline visualization

---

## 3. Layout & Structure

### Navigation
Tab-based, bottom navigation with 4 tabs:
1. **Pulse** — Dashboard & insights
2. **Timeline** — Emotional history
3. **Capture** — Quick moment recording
4. **Privacy** — Data controls

No nested navigation beyond a single detail push. Simple, flat hierarchy.

### Screen Flow
```
Tab Bar
├── Pulse (Home)
│   └── Insight Card Detail (push)
├── Timeline
│   └── Day Detail (push)
├── Capture
│   ├── Photo Mode
│   ├── Voice Mode
│   └── Journal Mode
│       └── Analysis Result (sheet)
└── Privacy
    ├── Data Sources (push)
    └── Individual Data Deletion (push)
```

### Responsive Strategy
Designed for iPhone only (Round 1). Portrait orientation. Single-column layout throughout.

---

## 4. Features & Interactions

### 4.1 Data Sources Screen
**Accessible from:** Privacy tab → "Data Sources"

Allows user to connect/disconnect:
- **Photos Library** — requests read access via PhotoKit
- **Voice Notes** — uses Speech framework + Voice Memos integration
- **Calendar** — reads events via EventKit
- **Journal Entries** — manual text entry, stored locally

**States:**
- Not Connected (grayed, with "Connect" button)
- Connected (green checkmark, with "Disconnect" option)
- Syncing (animated pulse indicator)

**Interactions:**
- Toggle connection → immediate permission request if enabling
- Disconnect → confirmation alert → data purge option

### 4.2 Pulse Dashboard
**Accessible from:** Pulse tab

The home screen. Shows:
- **Insight Card of the Week** — AI-generated summary card, e.g., "You were happiest on Tuesdays this month"
- **This Week's Mood Ring** — circular visualization of dominant emotions
- **Recent Captures** — last 3 moments with their emotional tags
- **Streak Counter** — days with at least one capture

**Insight Card:**
- Tappable → expands into full insight with supporting data points
- States: Loading (shimmer), Loaded (fade in), Error (retry button)
- Swipe left/right to browse multiple insights

### 4.3 Emotional Timeline
**Accessible from:** Timeline tab

A vertical scrolling timeline:
- **Day Rows** — date, dominant emotion color, summary phrase
- **Zoom Controls** — Day / Week / Month view
- **Color Coding** — emotional valence mapped to gradient colors:
  - Very Positive: Calm Sage
  - Positive: Gentle Gold
  - Neutral: Warm Gray
  - Negative: Muted Rose
  - Very Negative: Deep Ember

**Day Detail (push):**
- All moments captured that day
- Each moment card: timestamp, type icon, AI emotion tags, optional note
- Tap moment → full analysis sheet

### 4.4 Moment Capture
**Accessible from:** Capture tab (center tab button, elevated)

Three capture modes on a segmented picker:
1. **Photo** — opens camera/Library picker, captures image, immediately runs AI analysis
2. **Voice** — records up to 60 seconds, transcribes + analyzes tone/emotion
3. **Journal** — text input with optional prompt suggestions ("How are you feeling?", "What's on your mind?")

**After Capture:**
- Analysis runs on-device (Apple Intelligence)
- Results shown in sheet: emotion tags, optional "Add a note", Save/Delete
- Saved → stored in SQLite, appears in timeline

**Error Handling:**
- Microphone denied → explainer with Settings link
- Photo denied → explainer with Settings link
- Analysis fails → "Couldn't analyze this time" with retry

### 4.5 Privacy Dashboard
**Accessible from:** Privacy tab

Shows:
- **Data Summary** — "Pulse knows X photos, Y voice notes, Z journal entries about you"
- **Connected Sources** — list with status indicators
- **Data Controls**
  - "View all data Pulse has" → full data browser
  - "Export my data" → generates JSON file, share sheet
  - "Delete all data" → double confirmation, full wipe
- **Privacy Score** — visual meter (encryption status, data minimization, etc.)
- **Sync Status** — if enabled, shows E2E encryption badge

---

## 5. Component Inventory

### InsightCard
- States: Loading (shimmer skeleton), Loaded, Expanded
- Gradient background (emotion-colored), rounded 16pt corners
- Title: serif, 20pt, charcoal
- Body: sans, 14pt, warm gray
- Shadow: subtle warm shadow (0, 4, 16, 0.08)

### EmotionTag
- Pill shape, 8pt radius
- Background: emotion color at 20% opacity
- Text: emotion color, 12pt, medium weight
- Size: fits content + 16pt horizontal padding

### MomentCard
- White background, 16pt corners, subtle shadow
- Left accent bar: emotion color (4pt wide)
- Icon: SF Symbol, 24pt, emotion color
- Title: sans, 16pt, charcoal
- Timestamp: mono, 12pt, warm gray
- Tags row: up to 3 EmotionTags

### TimelineDayRow
- Full width, 72pt height
- Left: date (day number large, month small)
- Center: emotion color bar with summary phrase
- Right: chevron

### CaptureButton
- 64pt circle, Muted Rose gradient
- SF Symbol icon, white, 28pt
- On press: scale to 0.92, 100ms
- On release: spring back, 300ms

### DataSourceToggle
- Row layout: icon, name, status badge, toggle
- Connected: green dot + "Connected"
- Disconnected: gray dot + "Not connected"

---

## 6. Technical Approach

### Architecture
**MVVM with SwiftUI**
- Models: Plain Swift structs
- Services: Singleton managers for database, permissions, AI
- ViewModels: `@Observable` classes (iOS 26)
- Views: SwiftUI views, fully declarative

### Data Layer
- **SQLite.swift** for local persistence
- Tables: `moments`, `emotions`, `insights`, `data_sources`
- All data encrypted at rest via iOS Data Protection

### AI / Analysis
- **Apple Intelligence** on-device APIs (when available)
- Fallback: rule-based keyword sentiment analysis
- Analysis runs async, non-blocking

### Frameworks
| Framework | Purpose |
|---|---|
| SwiftUI | UI |
| SQLite.swift | Local database |
| PhotosUI | Photo picker |
| Photos | PhotoKit |
| EventKit | Calendar access |
| Speech | Voice transcription |
| NaturalLanguage | Sentiment analysis |
| CloudKit | Optional E2E sync |

### File Structure
```
Pulse/
├── App/
│   ├── PulseApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Moment.swift
│   ├── Emotion.swift
│   ├── Insight.swift
│   └── DataSource.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── AnalysisService.swift
│   ├── PermissionService.swift
│   └── InsightService.swift
├── ViewModels/
│   ├── PulseViewModel.swift
│   ├── TimelineViewModel.swift
│   ├── CaptureViewModel.swift
│   └── PrivacyViewModel.swift
├── Views/
│   ├── Pulse/
│   │   ├── PulseView.swift
│   │   └── InsightCardView.swift
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── TimelineDayRow.swift
│   │   └── DayDetailView.swift
│   ├── Capture/
│   │   ├── CaptureView.swift
│   │   ├── PhotoCaptureView.swift
│   │   ├── VoiceCaptureView.swift
│   │   └── JournalCaptureView.swift
│   ├── Privacy/
│   │   ├── PrivacyView.swift
│   │   ├── DataSourcesView.swift
│   │   └── DataBrowserView.swift
│   └── Components/
│       ├── EmotionTag.swift
│       ├── MomentCard.swift
│       ├── PulseButton.swift
│       └── LoadingShimmer.swift
├── Theme/
│   ├── Colors.swift
│   ├── Typography.swift
│   └── Animations.swift
└── Resources/
    └── Assets.xcassets
```

### Minimum Deployment
iOS 26.0 (to leverage latest SwiftUI and Apple Intelligence features)

### CloudKit E2E Sync (Future)
Round 2 feature. Architecture designed to support it:
- CloudKit container with CKSubscription
- User-controlled encryption keys stored in Keychain
- Conflict resolution: last-write-wins with merge for non-conflicting fields
