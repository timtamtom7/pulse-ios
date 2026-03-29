# Pulse iOS — R13: Polish & Launch

## Goal
Ship a polished, accessible, App Store-ready Pulse app: full UI audit, accessibility pass, dark/light mode, and launch readiness checklist.

---

## Scope

### Launch Checklist
- [ ] TestFlight build submitted and passing
- [ ] Beta eligibility confirmed in App Store Connect
- [ ] Export Compliance: No, or yes if cryptography used (document which)
- [ ] Age Rating: 4+ (no age restrictions)
- [ ] Privacy Nutrition Labels: Photos, Microphone, Speech, Calendar — all declared
- [ ] 5.5" + 6.7" screenshots (iPhone) + iPad screenshots
- [ ] App preview video (capture flow, insight reveal)
- [ ] Localized description: English first, Localization-ready strings

### UI Polish Pass
- All screens in both light (Cream `#FDF8F3`) and dark mode (Deep Ember `#3D3531`)
- No hardcoded hex values — all colors from `Theme/Colors.swift`
- Sheet backgrounds: `Material` effect or adaptive surface color
- Contrast ratio ≥ 4.5:1 for all text, ≥ 3:1 for large text
- Card shadows: warm shadow `rgba(61, 53, 49, 0.08)` — consistent across app

### Animation Audit
- All animations respect `AccessibilityReduceMotion`
- Default: 400-600ms ease-in-out transitions
- No animation duration hardcoded — use `Theme/Animations.swift` constants
- Loading shimmer for async content (emotion tag shimmer, insight card shimmer)
- Spring animation for `CaptureButton` press/release

### Accessibility Audit
- Every interactive element: `accessibilityLabel` + `accessibilityHint`
- All `MomentCard` elements readable by VoiceOver in logical order
- `DynamicType` support: all body text uses `.body` style (scales automatically)
- Emotion colors never used as sole information carrier (always paired with label)
- Minimum tap target: 44×44pt

### App Store Listing
- Title: "Pulse — Emotional Insight"
- Subtitle: "Understand your emotional world"
- Description: 3800 char limit — highlight privacy-first, on-device AI, no subscription
- Keywords: emotional, journal, mood, wellness, privacy, self-awareness
- Promotional text: "All your moments. Zero cloud. 100% private."
- Support URL, Marketing URL, Privacy Policy URL (placeholder acceptable for test)

### Localization Prep
- All user-facing strings in `Localizable.strings`
- `genstrings` run against all Swift files
- No concatenated strings visible to user
- Dates/times use `DateFormatter` with locale

---

## Out of Scope
- Non-English App Store localization
- Subscription/paywall implementation
- Watch companion app

---

## Dependencies
- Full R11 + R12 implementation complete
- `Theme/Colors.swift`, `Theme/Typography.swift`, `Theme/Animations.swift` all implemented
- All views use semantic colors and standard typography

## Verification
- Build passes
- `accessibilityInspect` CI step: zero critical errors
- Dark/light mode: screenshots taken for all 4 tabs in both modes
- All 4 tabs navigable via VoiceOver from launch to detail
