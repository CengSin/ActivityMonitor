import Foundation
import SystemBridge

/// Immutable kernel graphics accounting shared by process rows and bounded history.
/// A reference keeps the timestamp and payload out of every copied process record.
/// These ledgers are not a complete Metal/VRAM inventory.
final class ProcessGraphicsMemorySample: Codable, Equatable, Identifiable {
  var id: Date { date }
  let date: Date
  let footprint: UInt64?
  let footprintCompressed: UInt64?
  let excluded: UInt64?
  let excludedCompressed: UInt64?
  let status: String

  static func == (lhs: ProcessGraphicsMemorySample, rhs: ProcessGraphicsMemorySample) -> Bool {
    lhs === rhs || (lhs.date == rhs.date && lhs.footprint == rhs.footprint
      && lhs.footprintCompressed == rhs.footprintCompressed && lhs.excluded == rhs.excluded
      && lhs.excludedCompressed == rhs.excludedCompressed && lhs.status == rhs.status)
  }

  init(_ details: AMMemoryDetails, date: Date) {
    self.date = date
    func value(_ value: Int64) -> UInt64? {
      details.graphicsAccessible != 0 && value >= 0 ? UInt64(value) : nil
    }
    footprint = value(details.graphicsFootprint)
    footprintCompressed = value(details.graphicsFootprintCompressed)
    excluded = value(details.graphicsNoFootprint)
    excludedCompressed = value(details.graphicsNoFootprintCompressed)
    if details.graphicsAccessible == 0 {
      status = details.vmError == 0
        ? "Graphics ledgers unavailable on this task-info revision"
        : "Graphics ledgers unavailable: macOS task inspection failed (\(details.vmError))"
    } else if [footprint, footprintCompressed, excluded, excludedCompressed].contains(where: { $0 == nil }) {
      status = "Partial graphics accounting: invalid ledger balances are unavailable"
    } else {
      status = "Kernel graphics accounting · TASK_VM_INFO"
    }
  }
}
