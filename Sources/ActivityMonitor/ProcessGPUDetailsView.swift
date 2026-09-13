import Charts
import SwiftUI

struct ProcessGPUDetailsView: View {
  let history: [ProcessGraphicsMemorySample]
  let activity: [GPUProcessDeviceSample]
  let devices: [GPUDeviceSample]
  let range: Int
  let theme: MonitorTheme

  private let titles = ["Charged", "Charged compressed", "Excluded", "Excluded compressed"]
  private var visible: [ProcessGraphicsMemorySample] {
    guard let end = history.last?.date else { return [] }
    return history.filter { $0.date >= end.addingTimeInterval(-Double(range) * 60) }
  }
  private func values(_ sample: ProcessGraphicsMemorySample) -> [UInt64?] {
    [sample.footprint, sample.footprintCompressed, sample.excluded, sample.excludedCompressed]
  }
  private var colors: [Color] { [theme.blue, theme.purple, theme.green, theme.amber] }

  var body: some View {
    DiagnosticPanel(theme: theme) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Process graphics memory").font(.system(size: 13, weight: .semibold))
        Text(history.last?.status ?? "Waiting for process graphics accounting")
          .font(.system(size: 10)).foregroundStyle(theme.secondary)
        let points = titles.indices.flatMap { index in
          ResourceChartData.points(visible.map { ($0.date, values($0)[index]) }, title: titles[index])
        }
        if !points.isEmpty {
          Chart(points) { point in
            LineMark(x: .value("Time", point.date), y: .value("Bytes", point.value),
                     series: .value("Segment", point.series))
              .foregroundStyle(by: .value("Counter", point.title))
          }
          .chartForegroundStyleScale(domain: titles, range: colors)
          .chartYScale(domain: 0...max(1, (points.map(\.value).max() ?? 0) * 1.12))
          .chartYAxis {
            AxisMarks(position: .trailing) { value in
              AxisGridLine()
              AxisValueLabel {
                if let number = value.as(Double.self) { Text(ResourceChartData.byteLabel(number)) }
              }
            }
          }
          .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
          .frame(height: 170)
        }
        HStack {
          Text("Counter")
          Spacer()
          Text("Last reading").frame(width: 100, alignment: .trailing)
          Text("Peak").frame(width: 100, alignment: .trailing)
        }.font(.system(size: 10)).foregroundStyle(theme.secondary)
        ForEach(titles.indices, id: \.self) { index in
          HStack(spacing: 8) {
            Circle().fill(colors[index]).frame(width: 6, height: 6)
            Text(titles[index])
            Spacer(minLength: 8)
            Text(history.last.flatMap { values($0)[index] }.map(bytes) ?? "—")
              .frame(width: 100, alignment: .trailing)
            Text(visible.compactMap { values($0)[index] }.max().map(bytes) ?? "—")
              .frame(width: 100, alignment: .trailing)
          }.font(.system(size: 11)).monospacedDigit()
        }
        if let date = history.last?.date {
          Text("Sampled " + date.formatted(date: .omitted, time: .standard))
            .font(.system(size: 10)).foregroundStyle(theme.tertiary)
        }
        Text("Charged graphics memory contributes to this process’s physical footprint; excluded memory does not. Compressed balances are logical bytes. These graphics-tagged kernel ledgers can include shared surfaces and are not a complete Metal allocation inventory, dedicated VRAM usage, or a per-device breakdown. Zero means a zero ledger balance, not proof that the process uses no GPU memory.")
          .font(.system(size: 10)).foregroundStyle(theme.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    DiagnosticPanel(theme: theme) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Process activity by GPU").font(.system(size: 13, weight: .semibold))
        if activity.isEmpty {
          Text("No driver execution counters reported for this process.")
            .font(.system(size: 11)).foregroundStyle(theme.secondary)
        }
        ForEach(activity) { device in
          VStack(alignment: .leading, spacing: 5) {
            HStack {
              Text(devices.first { $0.id == device.id }?.name ?? "GPU \(device.id)")
                .font(.system(size: 12, weight: .medium))
              Spacer()
              Text(device.percent.map { gpuPercent($0) + "%" } ?? "—").monospacedDigit()
            }
            Text("Observed time: \(gpuDuration(device.seconds)) · Measured clients: \(device.sampledClientCount)/\(device.clientCount) · Counters: \(device.counterCount)")
              .font(.system(size: 10)).foregroundStyle(theme.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        Text("Rates include only clients with valid consecutive samples. New or reset clients need a baseline; vanished clients retain observed time but have no current rate. Driver coverage may be partial. Overlapping work can exceed 100%.")
          .font(.system(size: 10)).foregroundStyle(theme.tertiary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
