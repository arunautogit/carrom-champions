# 🎱 Carrom Champions

A high-performance 3D Carrom board game built with **Godot 4.3**, fully optimized for **Web (HTML5 / WebGL 2.0)**, **GitHub Pages**, and **Google YouTube Playables**.

---

## 🎮 Play Online

Once deployed to GitHub Pages, the game is playable directly in any browser:
- **Live URL**: [https://arunautogit.github.io/carrom-champions/](https://arunautogit.github.io/carrom-champions/)

---

## 🚀 YouTube Playables Integration

The project adheres to Google's official [YouTube Playables Developer Guidelines](https://developers.google.com/youtube/gaming/playables).

### Integrated SDK Features:
1. **Core SDK Loader**: Loaded via official script tag in `<head>` (`https://www.youtube.com/game_api/v1`).
2. **Lifecycle Handlers**:
   - `ytgame.game.firstFrameReady()` is fired during splash screen boot (`scenes/splash/SplashScreen.gd`).
   - `ytgame.game.gameReady()` is fired once the game is interactive in `scenes/menu/MainMenu.gd`.
3. **Pausing & Resuming**:
   - `ytgame.system.onPause`: Gracefully halts the Godot SceneTree and mutes all audio buses.
   - `ytgame.system.onResume`: Resumes gameplay and restores user audio settings.
4. **Audio State Synchronization**:
   - `ytgame.system.onAudioEnabledChange`: Syncs Master audio volume with YouTube's player chrome mute/unmute state.
5. **Cloud Saves**:
   - Integrated with `ytgame.game.saveData` and `ytgame.game.loadData` inside `scripts/SaveManager.gd` for seamless cross-device persistence.
6. **IFrame & Sandbox Compatibility**:
   - Exported using Godot 4.3's **Single-Threaded WebGL 2** (`gl_compatibility`) renderer, eliminating `SharedArrayBuffer` / cross-origin isolation (COOP/COEP) constraints inside embedded iframes.
7. **Offline / Standalone Fallback**:
   - Includes a sandbox mock so the game runs outside the YouTube container (e.g. locally or on GitHub Pages) without errors.

---

## 📦 How to Build the YouTube Playables Package

### Option 1: Automated Script (Windows PowerShell)
Run the bundled build script from the repository root:
```powershell
.\scripts\export_playables.ps1
```
This produces:
- `export/playables/` — Clean unpacked HTML5 bundle with `index.html` at the root.
- `export/CarromChampions_YouTubePlayables.zip` — Certified zip package ready for YouTube Developer Console upload.

### Option 2: Automated GitHub Actions CI/CD
Every push to `main` triggers `.github/workflows/deploy.yml`:
1. Compiles the Godot Web project.
2. Deploys the live game to **GitHub Pages**.
3. Uploads `CarromChampions_YouTubePlayables.zip` as a workflow release artifact.

---

## 🛠 Project Structure

```
├── .github/workflows/         # Automated GitHub Pages & Playables CI/CD
├── assets/                    # 3D models, textures, audio, fonts
├── export/
│   ├── youtube_playables/     # Custom HTML shell with YouTube SDK
│   └── playables/             # Compiled Web build output
├── scenes/                    # Game scenes (splash, menu, game, ui)
├── scripts/
│   ├── ai/                    # Carrom AI bots and shot evaluators
│   ├── managers/              # YouTubePlayablesBridge.gd, player profile
│   └── export_playables.ps1   # PowerShell export script
├── export_presets.cfg         # Android and Web export presets
├── project.godot              # Godot 4 engine configuration
└── README.md
```
