Activity Monitor 1.9.0 adds native software updates and gives more window space to charts and processes.

### Software updates

- Use **Check for Updates…** from the application menu or More menu to download and install new versions with Sparkle's native interface.
- Daily update checks are enabled by default. Opt into automatic downloads and installation, or disable background checks, from **Software Updates** in the application menu.
- Update feeds and archives are signed with Ed25519. Downloads are verified before extraction, and release publishing verifies the archive against the public key included in the app.

### More room for monitoring

- A compact, single-row overview header retains the GPU selector, history range, live/paused status, and help. Hover over the info button for a tooltip or click it to read the explanation.
- All six metric tabs now stay in the native macOS title bar. Narrow windows use icons; wider windows include labels and additional actions.
- Metric tabs use a single native glass outline on macOS Tahoe, removing the redundant border.
- A small gap below the title bar separates metric tabs from the overview controls at every window size.
- Native window controls support normal window dragging, zooming, and full screen. Keyboard shortcuts and distinct accessibility labels remain available.

### Install

Download the universal DMG or ZIP for Apple silicon and Intel on macOS 14 or later. Install 1.9.0 once from the download to enable built-in updates; earlier releases do not include the updater. SHA256SUMS verifies the downloads.

[Changes since 1.8.1](https://github.com/wieslawsoltes/ActivityMonitor/compare/v1.8.1...v1.9.0)
