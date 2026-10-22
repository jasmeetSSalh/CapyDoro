<p align="center">
  <img src="Art/app-icon/generated/icon-1024.png" width="128" alt="CapyDoro app icon: a capybara in a beanie with a tomato on its head">
</p>

# CapyDoro

A Pomodoro timer that lives in your Mac's menu bar, with a little capybara that walks while
you focus, naps on short breaks and floats in a hot spring on long ones.

<p align="center">
  <img src="Art/sprites/preview/transitions.gif" width="800" alt="The menu bar capybara on a light and a dark menu bar: walking, flopping down for a nap, waking, diving into a hot spring, floating, then climbing out">
</p>

## Download

**[Download the latest CapyDoro (.zip)](https://github.com/jasmeetSSalh/CapyDoro/releases/latest)**. Needs **macOS 14 Sonoma or newer**, Apple Silicon or Intel.

1. Unzip it and drag **CapyDoro** into your **Applications** folder.
2. Double-click it. macOS will say it "can't be opened", because the app isn't signed with a
   paid Apple developer account. Click **Done**.
3. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to
   CapyDoro. Confirm with your password. You only do this once.
4. A capybara and **25:00** appear in your menu bar (there's no Dock icon). Click it, press
   **Start**, and allow notifications when asked.

To quit, click it and choose **Quit CapyDoro**. If you don't see it, your menu bar may be full;
quit a few other menu bar apps to make room.

## What it does

- Classic cycle: 25 min focus → 5 min short break, and a 15 min long break after every 4th focus.
- Start, Pause, Resume, Skip and Reset from the menu bar.
- A notification and a chime when each phase ends.
- Settings: lengths, sessions before a long break, chime on/off, auto-start the next phase,
  capybara animation on/off, and open at login.
- Remembers your session if you quit it or restart your Mac. Choose **Reset** to start fresh.
- The capybara has a pose for every state, and short transitions between them. It respects
  **Reduce Motion**, and the animation only runs while the timer runs.

## Build from source

Made with Xcode 27.1 (older versions may not open the project).

```bash
git clone https://github.com/jasmeetSSalh/CapyDoro.git
cd CapyDoro
open CapyDoro.xcodeproj        # then ⌘R to run, ⌘U to run the tests
```

From the terminal:

```bash
xcodebuild -scheme CapyDoro -destination 'platform=macOS' test
./scripts/package.sh           # builds dist/CapyDoro-<version>.zip
```

The app uses Apple frameworks only (SwiftUI, Observation, UserNotifications, ServiceManagement);
there are no third-party dependencies.

The sprites and icons are generated from the drawings in `Art/` by `Art/tools/make_sprites.py`
and `Art/tools/make_icon.py` (Python 3 with Pillow). Rerun them after changing any drawing.

## Credits

- Capybara art: Jasmeet Salh. Animation frames, poses and transitions are generated from
  those drawings.
- Chime: "Victory Chime" by scratchonix, from [Pixabay](https://pixabay.com/) (Pixabay Content
  License), trimmed and faded.
- `Art/sound/Fluffing-a-Duck(chosic.com).mp3` (not used in the app): "Fluffing a Duck" by
  Kevin MacLeod ([incompetech.com](https://incompetech.com)), licensed under
  [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/), via chosic.com.

## License

The code is under the [MIT License](LICENSE). The capybara artwork in `Art/` and the generated
icons and sprites are not covered by it. Please don't reuse them without asking. The audio files
keep their own licenses (see Credits).
