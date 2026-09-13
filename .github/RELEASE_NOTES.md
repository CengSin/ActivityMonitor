Activity Monitor 1.7.0 adds process memory diagnostics and improves GPU monitoring and fullscreen menu-bar behavior.

### New

- Inspect physical footprint, resident, private/shared resident, compressed and purgeable memory in process diagnostics, with charts, last readings and visible-range peaks.
- View driver-reported GPU memory in use and allocated for each device and in an aggregate chart. Per-process GPU allocation remains explicitly unavailable where macOS provides no reliable counter.
- Export bounded process memory and device GPU memory histories with diagnostic snapshots.

### Fixed and improved

- Memory charts preserve unavailable-data gaps and long observation gaps. Detailed region readings retain their own timestamps between lightweight updates.
- Resident fallback is excluded from the physical-footprint composition series, and large counter values cannot overflow chart label conversion.
- Memory histories retain fifteen minutes at normal sampling cadence with explicit sample bounds.
- Process icon retention is limited to 128 process identities and a shared thumbnail cache with an 8 MiB cost target.
- The status-item popover joins fullscreen Spaces without activating the main window.
- Intel GPU contexts with direct accumulated execution counters now produce process GPU rates without double counting AppUsage arrays.
- GPU top-process lists show measured positive activity and an explicit empty state.

The memory investigation found that this app still uses more physical memory than Apple's built-in Activity Monitor in the recorded comparison. This release does not claim to meet a lower absolute footprint.

### Install

Download the universal DMG or app ZIP for Apple silicon and Intel on macOS 14 or later. Drag Activity Monitor to Applications. SHA256SUMS verifies the downloads.

[Memory investigation](https://github.com/wieslawsoltes/ActivityMonitor/blob/main/docs/performance/MEMORY.md) · [Process diagnostics guide](https://github.com/wieslawsoltes/ActivityMonitor/blob/main/docs/diagnostics/README.md)

[Changes since 1.6.3](https://github.com/wieslawsoltes/ActivityMonitor/compare/v1.6.3...v1.7.0)
