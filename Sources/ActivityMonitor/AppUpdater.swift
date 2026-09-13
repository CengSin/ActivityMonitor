import AppKit
import Combine
import Sparkle
import SwiftUI

/// One updater survives window closure and menu-bar-only monitoring.
@MainActor final class AppUpdater: ObservableObject {
  static let shared = AppUpdater()
  let controller: SPUStandardUpdaterController
  @Published private(set) var canCheckForUpdates = false
  @Published private(set) var automaticChecks = false
  @Published private(set) var automaticDownloads = false
  private var started = false

  private init() {
    controller = SPUStandardUpdaterController(
      startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    controller.updater.publisher(for: \.automaticallyChecksForUpdates).assign(to: &$automaticChecks)
    controller.updater.publisher(for: \.automaticallyDownloadsUpdates).assign(to: &$automaticDownloads)
  }

  func start() {
    // `swift run` and headless tests have no distributable bundle to replace.
    guard !started, Bundle.main.bundleURL.pathExtension == "app",
      Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil else { return }
    started = true
    controller.startUpdater()
  }

  func checkForUpdates() { controller.checkForUpdates(nil) }
  func setAutomaticChecks(_ enabled: Bool) {
    controller.updater.automaticallyChecksForUpdates = enabled
  }
  func setAutomaticDownloads(_ enabled: Bool) {
    controller.updater.automaticallyDownloadsUpdates = enabled
  }

  func addMenuItems(to menu: NSMenu) {
    let check = NSMenuItem(
      title: "Check for Updates…", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
      keyEquivalent: "")
    check.target = controller
    menu.addItem(check)
    menu.addSettingsAction("Automatically check for updates", checked: automaticChecks) {
      self.setAutomaticChecks(!self.automaticChecks)
    }
    menu.addSettingsAction("Automatically download and install updates", checked: automaticDownloads) {
      self.setAutomaticDownloads(!self.automaticDownloads)
      if self.automaticDownloads { self.setAutomaticChecks(true) }
    }
  }
}

struct UpdateCommands: View {
  @ObservedObject private var updater = AppUpdater.shared
  var body: some View {
    Button("Check for Updates…", action: updater.checkForUpdates)
      .disabled(!updater.canCheckForUpdates)
    Menu("Software Updates") {
      Toggle("Automatically check for updates", isOn: Binding(
        get: { updater.automaticChecks }, set: updater.setAutomaticChecks))
      Toggle("Automatically download and install updates", isOn: Binding(
        get: { updater.automaticDownloads }, set: updater.setAutomaticDownloads))
        .disabled(!updater.automaticChecks)
    }
  }
}
