# Stillpoint

*A quiet place for one thing at a time.*

Stillpoint is a native iOS deep-focus app. You name one intention, settle in with a minute of guided breathing and a live-synthesised soundscape, then work while a luminous orb slowly calms as your attention settles. When a stray thought pulls at you, you park it in a few words and keep going. Afterwards a short reflection feeds an insights engine that learns when, and how, you focus best.

Built with SwiftUI for iOS 26, Swift 6 strict concurrency, SwiftData, Metal shaders, AVAudioEngine, ActivityKit, WidgetKit and App Intents. It uses no third-party dependencies, no network, no accounts and no tracking.

---

## Features

### The session
- **Living orb.** A Metal shader (domain-warped gradient noise with pseudo-3D lighting) rendered live. Its turbulence follows a *calm model*: restless when you begin, still after about a quarter of an hour without interruptions.
- **Three depth stages:** *Settling in* → *Focused* (5 min) → *Deep focus* (15 min). Parking a thought halves your calm, because noticing a distraction is better than following it. A pause resets it.
- **Duration dial.** Drag the knob around the orb, in 5-minute steps with haptic ticks, or pick a preset. **∞** starts an open-ended flow session.
- **Park a thought.** Capture a distraction without leaving the session. A ripple crosses the orb and the thought waits in the *Parked* inbox.
- **Keep flowing.** When the planned time is up, a singing bowl rings and the timer counts on (`+04:12`) instead of cutting you off. This is configurable.
- **Hold to end.** Ending early takes a deliberate 1.2-second hold. Once the goal is reached, finishing is a single tap.
- **Immersive mode.** Controls fade after 8 quiet seconds; tap anywhere to bring them back. They never hide while VoiceOver is running.
- **Crash-safe.** Sessions are timed from wall-clock dates, not ticking counters, and persisted continuously. If iOS kills the app mid-session, or even mid-reflection, it comes back exactly where it was.

### Arrive (guided breathing)
- Four patterns: physiological sigh, box, coherent (5.5 bpm) and 4-7-8.
- The orb expands with your lungs, with cosine-eased fullness.
- Core Haptics swell on the inhale and ebb on the exhale, so you can follow with your eyes closed.
- Available before any session (about a minute, rounded to whole cycles) or on its own from the home screen.

### Soundscapes, synthesised live
No audio files. Each layer is DSP running on the real-time audio thread, mixed with click-free per-sample smoothing and soft-clipped:

| Layer | How it's made |
|---|---|
| Rain | Band-limited pink noise, plus individually synthesised droplets: short rising sine "plips", the actual acoustics of a bubble trapped by a raindrop. Occasional heavy drips. |
| Shoreline | Two independent swells with irregular periods sweep a state-variable filter over pink noise, with foam hiss at the crest. |
| Hearth | A flickering brown-noise roar, plus resonant crackles that arrive in bursts, and the occasional pop. |
| Brown noise | Leaky-integrated white noise: deep and even, good at masking voices. |
| Warm drone | An A major add 9 chord on detuned wavetable oscillators, each note swelling on its own slow LFO, so it never quite repeats. |
| Binaural | Two pure tones a few hertz apart (theta, alpha, beta or gamma). The app is honest that the evidence is mixed. |
| Singing bowl | Inharmonic partials with near-unison pairs that beat against each other. Rings at the start and end of a session. |

Six presets, a per-layer mixer with live preview, and background audio. Layer loudness is calibrated by a unit test that renders every generator and measures RMS.

### Reflection and insights
- After each session: did the intention land (*Done / Partly / Not yet*), a 1–5 depth rating, the thoughts parked along the way (tick them off), and a note.
- **Insights tab:** today, streak (with best), last 7 days and average depth; a 7/30-day chart against your goal; a GitHub-style consistency heatmap; a through-the-day histogram; and searchable session history with editable reflections.
- **Insight engine:** plain-language findings that only appear once there's enough data:
  - "Your peak window is 9 AM–11 AM"
  - "Longer sessions run deeper"
  - "Breathing first helps"
  - "You follow through on 80% of intentions"
  - "Tuesdays are your strongest day"
  - "Momentum is building"
  - "49 thoughts parked, not chased"

### System integration
- **Live Activity and Dynamic Island:** countdown, progress and depth stage, ticked by the system so no updates are needed. The overtime count-up is shown as `+mm:ss`.
- **Widgets:** Today's Focus in small and medium sizes, plus lock-screen circular, rectangular and inline variants. Each shows goal progress, streak and the last 7 days. Widgets roll over at midnight even if the app isn't opened.
- **App Intents / Siri / Shortcuts / Action button:**
  - *Start Focus Session* (minutes, intention)
  - *Park a Thought*, which runs in the background without opening the app.
- Completion notification when the app isn't in the foreground; screen kept awake during sessions (optional).

### Design
- Four palettes (**Ember**, **Tide**, **Moss**, **Aurora**) that re-theme everything: orb, ambient mesh-gradient background, tint, charts, widgets and the Live Activity.
- Liquid Glass controls, New York serif for intentions and headings, film grain on dark gradients to prevent banding.
- Accessibility:
  - Dynamic Type throughout.
  - Reduce Motion slows the orb to a near standstill and swaps the breathing scale for opacity.
  - VoiceOver labels, adjustable actions for the dial and depth rating, and spoken phase cues while breathing.
  - Differentiate Without Colour marks on the heatmap.

---

## Building

Requirements: Xcode 26 or later (built and tested with Xcode 27 on the iOS 27 simulator), [XcodeGen](https://github.com/yonaskolb/XcodeGen), and the Metal toolchain component (`xcodebuild -downloadComponent MetalToolchain` if Xcode asks).

```bash
xcodegen generate
open Stillpoint.xcodeproj
```

Choose the **Stillpoint** scheme and run. To run on a physical device, set your team in *Signing & Capabilities* for both the app and the widget extension (they share the `group.dev.stillpoint.Stillpoint` App Group).

### Tests

```bash
xcodebuild -project Stillpoint.xcodeproj -scheme Stillpoint -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The Swift Testing suites cover:
- the session clock (pauses, overtime, encoding)
- the calm/depth model
- breathing state
- stats, streaks and the heatmap, with a fixed calendar and time zone
- the insight rules, including that they stay quiet without enough data
- widget snapshot rollover
- sound mixes, plus a render of every DSP layer checking for NaNs, clipping and loudness
- the session engine end to end: arrival, parking, pause, goal behaviour, discard, restore after termination, interrupted reflections, and abandoned-session clean-up

### Launch arguments

| Argument | Effect |
|---|---|
| `-seedSampleData` | Fills an empty store with ten weeks of believable history |
| `-skipOnboarding` | Starts on the main screen |
| `-fastSessions` | *Debug only.* A planned minute lasts two seconds |

Debug builds also have *Settings → Developer* actions to generate sample history or erase everything.

---

## Architecture

```
Shared/              Code compiled into both the app and the widget extension
  OrbPalette, FocusActivityAttributes, WidgetSnapshot, AppGroup
Stillpoint/
  App/               Entry point, root tabs, model container, launch arguments
  Models/            SwiftData models (FocusSession, ParkedThought), value records, sample data
  Session/           SessionEngine (state machine), SessionClock, CalmTracker, FocusDepth,
                     persistence, and every session/reflection view
  Focus/             Home screen: duration dial, presets, intention, options
  Breathing/         Patterns, BreathState, haptics, breathing views
  Sound/             SoundscapeEngine (AVAudioEngine), renderer, mixer UI
    DSP/             Generators, filters, noise, atomics, all real-time safe
  Insights/          StatsCalculator, InsightGenerator, charts, heatmap, history
  Thoughts/          Parked inbox
  Settings/          Preferences and settings UI
  Onboarding/
  Design/            Theme tokens, Metal shaders, orb views, ambient background
  Services/          Notifications, Live Activity, widget sync, screen wake
  Intents/           App Intents and App Shortcuts
StillpointWidgets/   Today widget family and the focus Live Activity
StillpointTests/     Swift Testing suites
```

**Key decisions**
- **Time is derived, never counted.** `SessionClock` stores the start, the pauses and the plan. Every value is a pure function of `Date`, so backgrounding, suspension and relaunches can't drift the timer.
- **Pure logic, thin views.** Clock, calm, breathing, stats and insights are `nonisolated` value types with no UIKit, SwiftUI or SwiftData dependencies, which keeps them easy to test. The app target uses main-actor default isolation; only the DSP is deliberately nonisolated.
- **Real-time audio done properly.** The render block is built in a nonisolated context, never main-actor code. It doesn't allocate or lock: the main thread writes `Atomic<UInt32>` targets, and the audio thread smooths toward them per sample. The engine is reference-counted by *reason* (session, preview, breathing, bell), so it fades in and out and stops when nobody needs it.
- **The orb is one shader** with two inputs that matter, `turbulence` and `energy`. Everything (depth, breathing, the goal bloom, pauses) is expressed through them.
- **Widgets read a snapshot,** not the database. The app writes a small JSON summary to the App Group after each change, and the widget re-bases it if a day has passed.

---

## Notes and limits

- Developed and verified on the iOS 27 simulator. Haptics and real speaker/headphone output need a device; the DSP is covered by the render tests.
- On the lock screen, iOS may hide the seconds of the Live Activity countdown; that's system behaviour.
- Binaural beats are offered as a sound option, not as a claim. The in-app copy says the research is mixed.
- The app is dark-only by design: the orb is a light source and reads best on a dark canvas.
