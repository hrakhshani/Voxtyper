# Voxtyper — Privacy Policy

_Last updated: 2026-05-14_

Voxtyper is a menu-bar dictation app for macOS. This policy explains what data Voxtyper handles, where it goes, and what stays on your Mac.

---

## The short version

- Voxtyper has **no servers** of its own. We do not collect, store, or transmit your data to any Voxtyper-operated infrastructure.
- Audio you speak is streamed **directly from your Mac to OpenAI** under your own API key. It does not pass through us.
- Your OpenAI API key, voice commands, and preferences are stored **locally** on your Mac.
- There is **no analytics, no telemetry, no advertising, no tracking**.

---

## What Voxtyper accesses on your device

Voxtyper requests two macOS permissions, both of which you grant explicitly the first time the app needs them:

- **Microphone access** — used only while the menu-bar icon is red (i.e. while you are actively dictating). Voxtyper does not listen in the background.
- **Accessibility access** — used to paste transcribed text into the app you are focused on and to simulate the `⌘V` / `Return` keystrokes. Voxtyper does not read content from other apps.

---

## What is sent to OpenAI

When you press the hotkey and speak, Voxtyper opens a WebSocket to OpenAI's Realtime API and streams 16 kHz PCM16 audio chunks under your own API key. OpenAI returns transcribed text. If you have enabled **Translate to English**, the transcript is also sent to OpenAI's Chat API for translation.

What OpenAI does with that audio and text is governed by **OpenAI's own privacy policy and API data-usage terms**, not by Voxtyper. As of writing, OpenAI does not train on data submitted through the API by default. Please review OpenAI's policy directly: https://openai.com/policies/privacy-policy

Voxtyper does not retain a copy of the audio, the transcript, or the translation after it has been pasted into your focused app.

---

## What is stored locally

The following are stored in macOS `UserDefaults` on your Mac and never leave the device through Voxtyper:

- Your OpenAI API key
- Your spoken-language preference
- The translate-to-English toggle
- Your global hotkey binding
- Your voice-command list (keyword → shell command pairs)

If you delete the app, removing the app's preferences (`~/Library/Preferences/`) removes these.

---

## Voice commands

Voice commands run **local shell commands on your Mac** when a matching keyword is spoken. Voxtyper does not transmit voice-command keywords or shell commands anywhere. The shell command runs under your user account with the permissions you already have.

---

## Children

Voxtyper is not directed at children under 13 and does not knowingly collect data from anyone.

---

## Changes

If this policy changes, the updated version will be published in this file with a new "Last updated" date.

---

## Contact

Questions or concerns about privacy? Reach out via the contact information in [SUPPORT.md](SUPPORT.md).
