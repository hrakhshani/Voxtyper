# Voxtyper

> **Your voice is the keyboard.**
> A hands-free, polyglot dictation companion for macOS that turns your voice — in any language — into pristine text in *any* app, and lets you trigger scripts just by saying the word.

### Why I built this

I kept hitting the same wall. While working with AI coding tools, I often wanted to think out loud in my native language and have the prompt land in English. The same thing happened in Google Docs — I'd draft something more naturally in my own tongue, then end up typing it twice. Switching languages mid-flow felt like a tax on thinking. So I wrote Voxtyper: hold a hotkey, speak in whatever language fits the moment, and the translated text drops into whatever app I'm already in. No detours, no copy-paste dance.

---

Voxtyper is a tiny menu-bar app that lives quietly in the corner of your screen, waits for your hotkey, and then listens. Whatever you say streams in real time to OpenAI's Realtime API, is transcribed (and optionally translated to English on the fly), and lands inside whichever app your cursor is in — Slack, Mail, Safari, your IDE, ChatGPT, a terminal. There is no separate window to switch to. There is no "send" button to click. You speak, and it appears.

Your keyboard is now optional.

---

## Why Voxtyper

Most dictation tools force you into their own text box. They support one language. They can't fire off a script. They make you stop, copy, paste, edit, and switch apps.

Voxtyper was built around three convictions:

- **The cursor is the canvas.** Whatever app you're already in *is* the dictation target. No detours.
- **Your tongue is not a bug.** Speak Persian, Japanese, German, Arabic — Voxtyper handles thirteen languages out of the box, and can translate to English in flight so it doesn't matter what tongue you happen to be thinking in.
- **Words can do things.** Say a keyword you've registered, and Voxtyper runs the corresponding shell command. "Open Slack." "Lock screen." "Deploy staging." Your voice becomes a launcher.

It is built for people who type for a living, people who switch languages mid-sentence, people with RSI, accessibility users, multitaskers, parents holding a baby, and anyone who has ever thought *I wish I could just say this and have it appear.*

---

## Features

- **Global hotkey, anywhere.** Press your shortcut (default `⌃⌥⌘D`) from any app to start and stop listening. Fully rebindable.
- **Real-time streaming transcription** via OpenAI's Realtime API — words appear as soon as you've spoken them, not after you stop.
- **Translate-as-you-speak.** Toggle on translation and Voxtyper will transcribe your spoken language, run it through GPT, and paste the English result.
- **Drop text into any app.** Voxtyper uses native accessibility APIs to paste straight into the focused field. Slack, VS Code, your browser, your terminal — it doesn't care.
- **Voice commands.** Register keyword → shell-command pairs. Say "lock screen" and Voxtyper runs `pmset displaysleepnow`. Say "open notes" and Notes launches. Build your own voice-driven launcher.
- **Auto-submit with "search".** End any phrase with the word *search* and Voxtyper presses Return for you — perfect for Google, ChatGPT, Spotlight, anything with a search box.
- **Thirteen languages**, including English, Spanish, French, German, Italian, Portuguese, Dutch, Japanese, Korean, Chinese, Russian, Arabic, and Persian.
- **Lives in the menu bar.** No dock icon. No window stealing focus. Just a microphone that turns red when it's listening.
- **Your key, your data.** Bring your own OpenAI key. Audio streams directly from your Mac to OpenAI; nothing routes through a third-party server.

---

## How it works

```
  ┌─────────┐      ┌──────────────┐      ┌──────────────┐      ┌────────────┐
  │ Hotkey  │ ───► │ Audio capture│ ───► │ OpenAI       │ ───► │ Paste into │
  │ pressed │      │ PCM16 stream │      │ Realtime API │      │ focused    │
  └─────────┘      └──────────────┘      └──────────────┘      │ app        │
                                                │              └────────────┘
                                                │ optional
                                                ▼
                                         ┌──────────────┐
                                         │ Chat API     │
                                         │ translate→en │
                                         └──────────────┘
```

When you press the hotkey, [AudioRecorder.swift](SpeechTranslator/AudioRecorder.swift) opens the mic at 16 kHz mono PCM16 and streams chunks over a WebSocket to OpenAI via [RealtimeService.swift](SpeechTranslator/RealtimeService.swift). Server-side voice-activity detection decides when you've finished a thought. The transcript comes back, gets matched against your voice commands ([App.swift:215](SpeechTranslator/App.swift#L215)), and is then handed to [PasteService.swift](SpeechTranslator/PasteService.swift), which puts the text on the clipboard and synthesises a `⌘V`. If translation is enabled, the transcript takes a side trip through [OpenAIService.swift](SpeechTranslator/OpenAIService.swift) first.

The whole pipeline is about 700 lines of Swift. Read it, fork it, bend it to your workflow.

---

## Getting started

### Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+
- An [OpenAI API key](https://platform.openai.com/api-keys) with access to the Realtime API

### Build & run

```bash
git clone <this-repo>
cd speach-to-text
open SpeechTranslator.xcodeproj
```

Then in Xcode: select the `SpeechTranslator` scheme and press `⌘R`.

### First-launch setup

1. Click the microphone icon in your menu bar → **Settings…**
2. Paste your OpenAI API key.
3. Pick your spoken language.
4. (Optional) Toggle **Translate to English** if you want your speech translated as it's transcribed.
5. (Optional) Bind a different global hotkey.
6. (Optional) Add voice commands — a keyword and the shell command it should run.
7. Save.

macOS will ask twice: once for **Microphone** access, once for **Accessibility** (needed to paste into other apps). Grant both.

That's it. Press your hotkey from anywhere and start talking.

---

## Voice commands

Voice commands turn Voxtyper into a programmable launcher. Each command is a keyword → shell command pair. When the transcribed text exactly matches the keyword (case-insensitive), Voxtyper runs the command instead of pasting the text.

| Keyword         | Terminal command                              |
|-----------------|-----------------------------------------------|
| open slack      | `open -a Slack`                               |
| lock screen     | `pmset displaysleepnow`                       |
| sleep computer  | `pmset sleepnow`                              |
| deploy staging  | `cd ~/work/app && ./scripts/deploy staging`   |
| morning brief   | `open https://news.ycombinator.com`           |

If translation is enabled, commands are matched against the *English* result — so you can speak the trigger in any language and define the keyword in English. Bilingual launching, free of charge.

---

## The "search" suffix

End any phrase with the word **search** and Voxtyper presses Return after pasting. This makes Voxtyper a one-shot voice interface for any search box on your Mac:

- Focus the Google bar, say *"best ramen near me search"* → Google opens results.
- Focus ChatGPT, say *"explain the Borrow Checker search"* → ChatGPT submits.
- Focus Spotlight, say *"calculator search"* → Calculator launches.

Saying *search* alone simply presses Return on whatever's already in the field.

---

## Privacy

- Voxtyper sends audio **directly** from your Mac to OpenAI. There is no Voxtyper-operated server, no analytics endpoint, no telemetry.
- Your API key is stored in `UserDefaults`. Treat the machine accordingly.
- Microphone is *only* active when the menu-bar icon is red. There is no background listening.

If you'd like a fully local pipeline (e.g. swap the Realtime API for Whisper.cpp on-device), the architecture is deliberately modular — `RealtimeService` is the only file you'd need to replace.

---

## Make it your own

Voxtyper is small on purpose. The whole app is a handful of Swift files designed to be read and remixed. A few ideas to inspire forks:

- **Streaming paste.** Type each delta as it arrives, so users see words appear *as* they speak.
- **Multi-target translation.** Replace English with any target language — instant subtitles for a video call, instant translation for a foreign colleague.
- **On-device mode.** Drop in Whisper.cpp or Apple's `Speech` framework for an offline build.
- **Project-aware commands.** Make the voice-command list change based on the frontmost app.
- **Punctuation prompts.** Teach the system prompt to format prose, code, or Markdown differently.

Pull requests and forks are warmly welcomed.

---

## Project layout

| File                                                                                        | Role                                                                              |
|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| [App.swift](SpeechTranslator/App.swift)                                                     | App entry point, menu-bar UI, settings window, voice-command dispatch             |
| [AudioRecorder.swift](SpeechTranslator/AudioRecorder.swift)                                 | Captures microphone audio as 16 kHz PCM16                                         |
| [RealtimeService.swift](SpeechTranslator/RealtimeService.swift)                             | WebSocket client for OpenAI's Realtime transcription API                          |
| [OpenAIService.swift](SpeechTranslator/OpenAIService.swift)                                 | REST client for Whisper + Chat (translation fallback)                             |
| [PasteService.swift](SpeechTranslator/PasteService.swift)                                   | Clipboard + simulated `⌘V` and `Return` keystrokes                                |
| [GlobalHotkey.swift](SpeechTranslator/GlobalHotkey.swift)                                   | Carbon-event-based system-wide hotkey                                             |

---

## App Store

If you're looking at Voxtyper from the App Store, two companion pages cover the non-technical side of the app:

- [Support](SUPPORT.md) — setup walkthrough, FAQ, troubleshooting, and how to reach a human.
- [Marketing](MARKETING.md) — the short pitch, audience, and language list (suitable for hosting as the App Store marketing page).

---

## License

MIT. Build whatever you want with it.

---

*Voxtyper exists because typing should be optional, languages shouldn't be barriers, and the most natural input device — your voice — should reach every corner of your computer.*
