import SwiftUI

struct ContentView: View {
    @State private var currentNumber: Int?
    @State private var history: [Int] = []
    @State private var isSpinning = false
    @State private var isStopping = false
    @State private var spinTimer: Timer?

    var body: some View {
        VStack {
            Spacer()

            // 履歴と現在の数字を表示
            VStack(spacing: 12) {
                // 履歴（上ほど薄い）
                ForEach(Array(history.enumerated()), id: \.offset) { index, number in
                    Text("\(number)")
                        .font(.system(size: 48, weight: .bold))
                        .opacity(opacity(for: index))
                }

                // 現在の数字（最も濃い）
                if let current = currentNumber {
                    Text("\(current)")
                        .font(.system(size: 72, weight: .bold))
                }
            }

            Spacer()

            // ダイスを振るボタン（画面下部）
            Button(isSpinning ? "ストップ" : "ダイスを振る") {
                if isSpinning {
                    stopSpinning()
                } else {
                    startSpinning()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
            .disabled(isStopping)
        }
    }

    private func startSpinning() {
        // 前回の結果を履歴に追加
        if let current = currentNumber {
            history.append(current)
            if history.count > 4 {
                history.removeFirst()
            }
        }

        isSpinning = true
        currentNumber = Int.random(in: 1...6)

        // 高速で数字を変更
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            currentNumber = Int.random(in: 1...6)
        }
    }

    private func stopSpinning() {
        isStopping = true
        spinTimer?.invalidate()

        // 徐々に遅くなりながら停止
        var delays: [Double] = [0.1, 0.15, 0.2, 0.3, 0.4, 0.5]
        var totalDelay = 0.0

        for delay in delays {
            totalDelay += delay
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                currentNumber = Int.random(in: 1...6)
            }
        }

        // 最終停止
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.3) {
            isSpinning = false
            isStopping = false
        }
    }

    private func opacity(for index: Int) -> Double {
        let count = history.count
        guard count > 0 else { return 1.0 }
        // 最も古い(index=0)が最も薄く、最も新しいが濃い
        // 最小opacity 0.2、最大 0.7
        let ratio = Double(index + 1) / Double(count)
        return 0.2 + (ratio * 0.5)
    }
}

#Preview {
    ContentView()
}
