# Pulse iOS — R11: AI Insights

## Goal
Deliver on-device emotional intelligence: surface patterns from journal entries, voice notes, and photos using Apple Intelligence and the NaturalLanguage framework.

---

## Scope

### Emotion ML Pipeline
- `AnalysisService`: Compose NaturalLanguage `NLTagger` pipeline for sentiment + keyword extraction on all text input (journal, transcribed voice)
- Tag each moment with emotion dimensions: valence (-1 to +1), energy (low/medium/high), anxiety (flag), gratitude (flag)
- Run analysis async, non-blocking; show shimmer → results

### Photo Emotion Analysis
- `VisionPhotoAnalysisService`: Use Vision framework to detect scene attributes (beach, city, nature, indoors) and object labels from captured photos
- Map Vision labels to emotional context: "beach/sunset" → relaxation/positive valence; "crowd/urban" → stimulation/anxiety
- Combine with optional Apple Intelligence image understanding when available on device

### Weekly AI Mood Report
- `InsightService`: Aggregate last 7 days of emotion data per user
- Generate plain-language digest: "You felt most grateful on Thursdays. Your energy peaked mid-week. Sleep-adjacent captures show 20% lower anxiety scores."
- Render as `InsightCard` on Pulse dashboard

### Personalized Insight Cards
- Pattern detection: correlate emotion scores with other signals (time of day, day of week, capture frequency)
- "When you capture more than 3 moments in a day, your average valence drops — consider spacing them out"
- "Your happiest captures tend to happen outdoors on weekends"

### Mood Ring Visualization
- Circular visualization on Pulse tab showing dominant emotion color blended across the week
- Animated update when new captures added
- Tap to expand into emotion breakdown (valence, energy, anxiety, gratitude as arcs)

### Insight Card Detail
- Push navigation from card → full insight detail
- Shows supporting data points (captures that contributed, trend lines)
- Swipe left/right to browse multiple insights

---

## Out of Scope
- Cloud-based LLM calls (all on-device)
- Cross-user comparison
- Medical or health diagnosis
- Export of raw analysis data

---

## Dependencies
- `Pulse/Models/Moment.swift`, `Emotion.swift`, `Insight.swift`
- `Pulse/Services/AnalysisService.swift` (existing, needs NL pipeline)
- `Pulse/Services/InsightService.swift` (existing, needs weekly digest)
- `Pulse/Services/DatabaseService.swift` (existing)
- `Pulse/Views/Pulse/InsightCardView.swift` (existing shell)
- `Pulse/Views/Pulse/PulseView.swift` (existing shell)

## Verification
- Build passes: `xcodebuild -scheme Pulse -configuration Debug -destination 'platform=iOS Simulator,arch=arm64' build CODE_SIGN_IDENTITY="-"` with no errors
- Unit tests: `Moment` → `Emotion` analysis returns non-nil tags
- UI test: capture journal entry → insight card appears within 3 seconds
