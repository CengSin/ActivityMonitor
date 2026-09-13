// Run with: swift scripts/gpu-memory-workload.swift
// Allocates and fills private Metal buffers, then reports independent memory counters.
import Darwin
import Foundation
import Metal

func capture(_ label: String, device: MTLDevice) {
  var info = task_vm_info_data_t()
  var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
  let status = withUnsafeMutablePointer(to: &info) {
    $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
      task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
    }
  }
  print("\(label): pid=\(getpid()) status=\(status) words=\(count) Metal.currentAllocatedSize=\(device.currentAllocatedSize) graphicsCharged=\(info.ledger_tag_graphics_footprint) graphicsChargedCompressed=\(info.ledger_tag_graphics_footprint_compressed) graphicsExcluded=\(info.ledger_tag_graphics_nofootprint) graphicsExcludedCompressed=\(info.ledger_tag_graphics_nofootprint_compressed)")
}
guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
  fatalError("Metal unavailable")
}
capture("baseline", device: device)
autoreleasepool {
  var buffers: [MTLBuffer] = []
  for _ in 0..<4 {
    guard let buffer = device.makeBuffer(length: 16 * 1024 * 1024, options: .storageModePrivate),
      let command = queue.makeCommandBuffer(), let blit = command.makeBlitCommandEncoder()
    else { fatalError("Metal allocation/encoding failed") }
    blit.fill(buffer: buffer, range: 0..<buffer.length, value: 123)
    blit.endEncoding()
    command.commit()
    command.waitUntilCompleted()
    guard command.status == .completed else { fatalError("Metal execution failed") }
    buffers.append(buffer)
  }
  withExtendedLifetime(buffers) { capture("64 MiB private buffers filled", device: device) }
  if CommandLine.arguments.contains("--hold") { Thread.sleep(forTimeInterval: 30) }
}
capture("buffers released", device: device)
