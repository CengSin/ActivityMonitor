import Foundation
import SystemBridge

/// Kernel graphics-tag accounting for one process, not a complete Metal/VRAM inventory.
struct ProcessGraphicsMemorySample: Codable, Equatable, Identifiable {
  var id: Date { date }
  var date: Date
  var footprint: UInt64?
  var footprintCompressed: UInt64?
  var excluded: UInt64?
  var excludedCompressed: UInt64?
  var status: String

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
