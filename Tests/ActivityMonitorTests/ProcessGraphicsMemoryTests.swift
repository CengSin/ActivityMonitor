import Darwin
import XCTest
import SystemBridge
@testable import ActivityMonitor

final class ProcessGraphicsMemoryTests: XCTestCase {
  func testNativeGraphicsReadAndDeniedAccess() throws {
    var memory = AMMemoryDetails()
    am_memory_details(getpid(), &memory)
    XCTAssertEqual(memory.vmError, 0)
    XCTAssertEqual(memory.graphicsAccessible, 1)
    let sample = ProcessGraphicsMemorySample(memory, date: Date())
    XCTAssertNotNil(sample.footprint)
    XCTAssertNotNil(sample.footprintCompressed)
    am_memory_details(-1, &memory)
    XCTAssertEqual(memory.graphicsAccessible, 0)
    XCTAssertNil(ProcessGraphicsMemorySample(memory, date: Date()).footprint)
  }
  func testMissingRevisionNegativeBalancesZeroAndJSONRoundTrip() throws {
    var memory = AMMemoryDetails()
    memory.graphicsFootprint = 300
    XCTAssertNil(ProcessGraphicsMemorySample(memory, date: Date()).footprint)
    memory.graphicsAccessible = 1
    memory.graphicsFootprint = -1
    let sample = ProcessGraphicsMemorySample(memory, date: Date())
    XCTAssertNil(sample.footprint)
    XCTAssertEqual(sample.footprintCompressed, 0)
    XCTAssertTrue(sample.status.contains("Partial"))
    let data = try JSONEncoder().encode(sample)
    XCTAssertEqual(try JSONDecoder().decode(ProcessGraphicsMemorySample.self, from: data), sample)
  }
  @MainActor func testGraphicsHistoryDeduplicatesCacheAndClearsOnFailure() throws {
    var row = ProcessRow(id: getpid(), parent: 1, uid: 501, start: 1, name: "test", user: "test",
      cpu: 0, cpuTime: 0, memory: 0, resident: 0, threads: 0, read: 0, written: 0,
      isApp: false, accessible: true, kind: "Apple", ioAccessible: true)
    let date = Date(timeIntervalSince1970: 0)
    var memory = AMMemoryDetails()
    memory.graphicsAccessible = 1
    memory.graphicsFootprint = 100
    row.details.graphics = .init(memory, date: date)
    XCTAssertEqual(ProcessValues.value(row, key: "graphicsMemory", metric: .gpu), .integer(100))
    let session = ProcessDiagnosticSession(row: row)
    for index in 0...10 { session.accept(rows: [row], date: date.addingTimeInterval(Double(index))) }
    XCTAssertEqual(session.graphicsHistory.count, 1)
    for index in 1...1000 {
      session.appendGraphics(.init(memory, date: date.addingTimeInterval(Double(index))))
    }
    XCTAssertEqual(session.graphicsHistory.count, 901)
    memory.graphicsAccessible = 0
    session.appendGraphics(.init(memory, date: date.addingTimeInterval(1001)))
    XCTAssertNil(session.graphicsHistory.last?.footprint)
    session.appendGraphics(.init(memory, date: date))
    XCTAssertGreaterThanOrEqual(session.graphicsHistory.first!.date, date.addingTimeInterval(101))
    row.details.graphics = .init(memory, date: date)
    XCTAssertNil(ProcessValues.value(row, key: "graphicsMemory", metric: .gpu))
    session.paused = true
    session.accept(rows: [row], date: date.addingTimeInterval(1002))
    XCTAssertEqual(session.graphicsHistory.last?.date, date.addingTimeInterval(1001))
  }
}
