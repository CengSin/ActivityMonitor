import AppKit
import SwiftUI
import XCTest

@testable import ActivityMonitor

@MainActor final class MetricSwitcherChromeTests: XCTestCase {
  func testOnlyTahoeNativeToolbarOwnsTheContainer() {
    for dark in [false, true] {
      for compact in [false, true] {
        let standalone = MetricSwitcher(
          metric: .constant(.memory), theme: .init(dark: dark), compact: compact)
        XCTAssertTrue(standalone.drawsContainer)
        let toolbar = MetricSwitcher(
          metric: .constant(.memory), theme: .init(dark: dark), compact: compact,
          controlHeight: 28, inNativeToolbar: true)
        if #available(macOS 26, *) {
          XCTAssertFalse(toolbar.drawsContainer)
        } else {
          XCTAssertTrue(toolbar.drawsContainer)
        }
      }
    }
  }

  func testNativeToolbarContainerDoesNotPaintOverItsHost() async throws {
    guard #available(macOS 26, *) else { throw XCTSkip("Native glass toolbar requires macOS 26") }
    for dark in [false, true] {
      for inToolbar in [false, true] {
        let host = NSHostingView(rootView:
          MetricSwitcher(
            metric: .constant(.memory), theme: .init(dark: dark), compact: true,
            controlHeight: 28, inNativeToolbar: inToolbar
          ).frame(width: 220, height: 40).background(Color(red: 1, green: 0, blue: 1)))
        host.frame = NSRect(x: 0, y: 0, width: 220, height: 40)
        let window = NSWindow(
          contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.contentView = nil; window.close() }
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(25))
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let scale = CGFloat(bitmap.pixelsWide) / host.bounds.width
        // The container's left inset, outside every button. Native-toolbar
        // content must leave the host surface intact; standalone owns its fill.
        let color = try XCTUnwrap(bitmap.colorAt(x: Int(2 * scale), y: Int(20 * scale))?
          .usingColorSpace(.sRGB))
        // Compare with the same capture's unobstructed corner: AppKit's color
        // management can change the numeric RGB values of the source magenta.
        let reference = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide - 1, y: 0)?
          .usingColorSpace(.sRGB))
        XCTAssertGreaterThan(reference.redComponent - reference.greenComponent, 0.3)
        XCTAssertGreaterThan(reference.blueComponent - reference.greenComponent, 0.3)
        let isHostColor = abs(color.redComponent - reference.redComponent) < 0.01
          && abs(color.greenComponent - reference.greenComponent) < 0.01
          && abs(color.blueComponent - reference.blueComponent) < 0.01
        XCTAssertEqual(isHostColor, inToolbar, "dark=\(dark), inToolbar=\(inToolbar)")
      }
    }
  }
}
