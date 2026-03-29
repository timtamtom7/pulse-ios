# PulseMac — Launch Checklist

## App Store Submission

- [ ] App Store screenshots generated (5 shots × 2 modes × 3 devices = 30 images)
- [ ] APPSTORE.md listing approved internally
- [ ] SCREENSHOTS.md specs followed exactly
- [ ] Mental health disclaimer present in listing
- [ ] Age rating confirmed: 12+
- [ ] Keywords optimized for discoverability
- [ ] Primary category: Health & Fitness → Mind & Body
- [ ] Secondary category: Lifestyle

## Build & Code Signing

- [ ] Debug build passes (`xcodebuild -scheme PulseMac -configuration Debug`)
- [ ] Release build passes (`xcodebuild -scheme PulseMac -configuration Release`)
- [ ] Apple Developer account active
- [ ] App Store Distribution certificate created
- [ ] Provisioning profile created for PulseMac
- [ ] Bundle identifier: `com.pulseapp.mac` (or registered ID)
- [ ] Version number set: `1.0.0` (or current)
- [ ] Build number incremented for each TestFlight upload

## TestFlight

- [ ] TestFlight build uploaded to App Store Connect
- [ ] TestFlight build passes Apple review (typically 24-48h)
- [ ] Internal testers group created
- [ ] Beta testers recruited (minimum 3-5 for feedback)
- [ ] External testers (public beta) opted-in if desired
- [ ] Feedback from testers incorporated
- [ ] Crash reports checked in App Store Connect

## Legal & Compliance

- [ ] Privacy policy URL ready and page live
- [ ] Privacy policy covers: data collected, local-only storage, no third-party data sharing
- [ ] Support URL ready (web page or `mailto:` link)
- [ ] Terms of Service page live (if required by region)
- [ ] Apple privacy nutrition labels completed in App Store Connect:
  - [ ] Does the app collect data? → Yes (local only, see privacy policy)
  - [ ] Data linked to you? → No
  - [ ] Data used to track you? → No
  - [ ] Third-party SDKs reviewed for compliance
- [ ] Mental health disclaimer confirmed in-app and in listing

## Marketing

- [ ] App Store listing submitted for review
- [ ] Review notes prepared for Apple reviewer (explain mental health context, 12+ rating justification)
- [ ] Promotional assets ready (optional)
- [ ] Social accounts informed at launch (if applicable)
- [ ] Press/media list identified (optional)

## Post-Launch

- [ ] Monitor App Store Connect for review status
- [ ] Set up App Store Connect analytics tracking
- [ ] Monitor crash reports and user feedback
- [ ] Plan for 1.0.1 bug fix release if needed
