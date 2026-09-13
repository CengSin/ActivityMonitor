Activity Monitor 1.8.1 adds per-process graphics memory accounting, more GPU activity details, and compact diagnostic help.

### New

- Track charged, charged compressed, excluded, and excluded compressed graphics memory for each accessible process using macOS task-memory ledgers.
- Sort processes by **Graphics charged**, inspect subtree subtotals, and view graphics-memory histories with last readings and visible-range peaks.
- Inspect per-GPU process execution rates, observed GPU time, measured/reporting client coverage, and execution-counter counts.
- Export timestamped graphics-memory histories and per-device process activity in diagnostic JSON.

### Improved

- Share immutable graphics-memory snapshots across process rows and histories to reduce copying during sorting and tree aggregation.

- Process-tree construction uses compact temporary graph state, avoids copying full records into traversal queues, and skips redundant filtering of complete snapshots.

- Diagnostic explanations and subtitles now use compact info buttons. Hover for a tooltip or click to keep the full explanation open; access errors and missing-data states remain visible.
- GPU tracking preserves missing/reset/warmup states, deduplicates reporting clients, and rebaselines after long observation gaps.
- Graphics accounting reuses the background task-memory query, checks returned API revisions, preserves measured zero, and keeps unavailable readings distinct.

Graphics ledgers are kernel accounting, not a complete Metal allocation inventory or dedicated VRAM total. Shared surfaces can overlap, and compressed balances are logical bytes. No private frameworks, root access, or task-control rights are required.

### Install

Download the universal DMG or app ZIP for Apple silicon and Intel on macOS 14 or later. Drag Activity Monitor to Applications. SHA256SUMS verifies the downloads.

[GPU memory API investigation](https://github.com/wieslawsoltes/ActivityMonitor/blob/v1.8.1/docs/diagnostics/GPU_MEMORY.md) · [Process diagnostics guide](https://github.com/wieslawsoltes/ActivityMonitor/blob/v1.8.1/docs/diagnostics/README.md)

[Changes since 1.7.0](https://github.com/wieslawsoltes/ActivityMonitor/compare/v1.7.0...v1.8.1)
