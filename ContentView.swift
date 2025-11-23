import SwiftUI

struct ContentView: View {
    @State private var currentNumber: Int = 1
    @State private var history: [Int] = []
    @State private var isSpinning = false
    @State private var isStopping = false
    @State private var spinTimer: Timer?
    @State private var hasStarted = false

    var body: some View {
        VStack {
            Spacer()

            // 履歴（上ほど薄い）
            VStack(spacing: 8) {
                ForEach(Array(history.enumerated()), id: \.offset) { index, number in
                    Text("\(number)")
                        .font(.system(size: 32, weight: .bold))
                        .opacity(historyOpacity(for: index))
                }
            }
            .padding(.bottom, 20)

            // スロットマシン風の数字表示
            if hasStarted {
                VStack(spacing: 4) {
                    // 上2つ目
                    Text("\(wrapNumber(currentNumber - 2))")
                        .font(.system(size: 36, weight: .medium))
                        .opacity(0.2)

                    // 上1つ目
                    Text("\(wrapNumber(currentNumber - 1))")
                        .font(.system(size: 48, weight: .medium))
                        .opacity(0.4)

                    // 中央（現在の数字）
                    Text("\(currentNumber)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(.primary)

                    // 下1つ目
                    Text("\(wrapNumber(currentNumber + 1))")
                        .font(.system(size: 48, weight: .medium))
                        .opacity(0.4)

                    // 下2つ目
                    Text("\(wrapNumber(currentNumber + 2))")
                        .font(.system(size: 36, weight: .medium))
                        .opacity(0.2)
                }
                .frame(height: 280)
                .clipped()
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

    // 1-6で循環させる
    private func wrapNumber(_ n: Int) -> Int {
        var result = n % 6
        if result <= 0 {
            result += 6
        }
        return result
    }

    private func startSpinning() {
        // 前回の結果を履歴に追加
        if hasStarted {
            history.append(currentNumber)
            if history.count > 4 {
                history.removeFirst()
            }
        }

        hasStarted = true
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
        let delays: [Double] = [0.1, 0.15, 0.2, 0.3, 0.4, 0.5]
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

    private func historyOpacity(for index: Int) -> Double {
        let count = history.count
        guard count > 0 else { return 1.0 }
        let ratio = Double(index + 1) / Double(count)
        return 0.2 + (ratio * 0.5)
    }
}

#Preview {
    ContentView()
}
