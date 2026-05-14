# Voxtyper — Support

Thanks for using **Voxtyper**, the hands-free, polyglot dictation companion for macOS. This page covers the most common questions, setup steps, and ways to reach a human if something isn't behaving the way you expect.

---

## Getting started

1. Launch Voxtyper. You'll see a microphone icon appear in your menu bar.
2. Open **Settings…** from the menu-bar icon.
3. Paste your OpenAI API key. (Get one at https://platform.openai.com/api-keys — your key needs Realtime API access.)
4. Choose your spoken language.
5. Grant macOS permissions when prompted:
   - **Microphone** — so Voxtyper can hear you.
   - **Accessibility** — so Voxtyper can paste text into other apps.
6. Press the default hotkey **⌃⌥⌘D** (rebindable) from any app to start and stop listening.

---

## Frequently asked questions

### Voxtyper isn't pasting into my app
Open **System Settings → Privacy & Security → Accessibility** and make sure Voxtyper is enabled. Quit and relaunch the app after granting access.

### The microphone never turns red / I don't hear anything happening
Open **System Settings → Privacy & Security → Microphone** and make sure Voxtyper is allowed. Then check that your input device is selected correctly in **System Settings → Sound → Input**.

### My API key isn't working
- Confirm the key is from https://platform.openai.com/api-keys and copied without extra spaces.
- Confirm your OpenAI account has billing set up and Realtime API access enabled.
- Try a fresh key if the old one was revoked.

### Translation isn't happening
Open **Settings…** and toggle **Translate to English** on. Translation runs only when this option is enabled.

### My voice command isn't firing
- Voice commands match the **transcribed text** exactly (case-insensitive).
- If translation is on, the match runs against the **English** result.
- Make sure the command's shell command actually works in Terminal first.

### Can I change the global hotkey?
Yes — open **Settings…** and rebind it under **Hotkey**.

### Which languages are supported?
English, Spanish, French, German, Italian, Portuguese, Dutch, Japanese, Korean, Chinese, Russian, Arabic, and Persian.

### What does the "search" suffix do?
End any phrase with the word *search* and Voxtyper presses Return for you after pasting. It's a one-shot voice interface for Google, ChatGPT, Spotlight, and any other search box.

---

## Privacy

- Voxtyper sends audio **directly** from your Mac to OpenAI. There is no Voxtyper-operated server, no analytics, no telemetry.
- Your OpenAI API key is stored locally on your Mac.
- The microphone is **only** active when the menu-bar icon is red. There is no background listening.

---

## System requirements

- macOS 14 (Sonoma) or later
- An OpenAI API key with Realtime API access
- Microphone and Accessibility permissions granted

---

## Contact

If you're stuck, found a bug, or have a feature idea, please reach out:

- **Email:** hrakhshani_68@yahoo.com
- **Issues & feature requests:** Open an issue in the project repository.

We try to respond within a couple of business days. When reporting a bug, please include:

- macOS version
- Voxtyper version
- A short description of what you were doing
- Whether translation was on or off
- Any error message you saw
