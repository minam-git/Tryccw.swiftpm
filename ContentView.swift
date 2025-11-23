import SwiftUI

struct ContentView: View {
    // 3つのダイスの状態
    @State private var diceNumbers: [Int] = [1, 1, 1]
    @State private var isSpinning: [Bool] = [false, false, false]
    @State private var isStopping: [Bool] = [false, false, false]
    @State private var spinTimers: [Timer?] = [nil, nil, nil]
    @State private var hasStarted = false

    var body: some View {
        VStack {
            Spacer()

            // 3つのダイスを横に並べる
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { index in
                    VStack {
                        // スロットマシン風の数字表示
                        if hasStarted {
                            slotView(for: index)
                        } else {
                            // 開始前のプレースホルダー
                            VStack(spacing: 4) {
                                Text("-")
                                    .font(.system(size: 28, weight: .medium))
                                    .opacity(0.2)
                                Text("-")
                                    .font(.system(size: 36, weight: .medium))
                                    .opacity(0.4)
                                Text("-")
                                    .font(.system(size: 56, weight: .bold))
                                Text("-")
                                    .font(.system(size: 36, weight: .medium))
                                    .opacity(0.4)
                                Text("-")
                                    .font(.system(size: 28, weight: .medium))
                                    .opacity(0.2)
                            }
                            .frame(width: 80, height: 220)
                        }

                        // 各ダイスのストップボタン
                        Button("ストップ") {
                            stopDice(index)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isSpinning[index] || isStopping[index])
                    }
                }
            }

            Spacer()

            // スタートボタン（画面下部）
            Button("スタート") {
                startAllDice()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
            .disabled(isSpinning.contains(true))
        }
    }

    // スロットマシン風の表示
    @ViewBuilder
    private func slotView(for index: Int) -> some View {
        let number = diceNumbers[index]
        VStack(spacing: 4) {
            // 上2つ目
            Text("\(wrapNumber(number - 2))")
                .font(.system(size: 28, weight: .medium))
                .opacity(0.2)

            // 上1つ目
            Text("\(wrapNumber(number - 1))")
                .font(.system(size: 36, weight: .medium))
                .opacity(0.4)

            // 中央（現在の数字）
            Text("\(number)")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.primary)

            // 下1つ目
            Text("\(wrapNumber(number + 1))")
                .font(.system(size: 36, weight: .medium))
                .opacity(0.4)

            // 下2つ目
            Text("\(wrapNumber(number + 2))")
                .font(.system(size: 28, weight: .medium))
                .opacity(0.2)
        }
        .frame(width: 80, height: 220)
    }

    // 1-6で循環させる
    private func wrapNumber(_ n: Int) -> Int {
        var result = n % 6
        if result <= 0 {
            result += 6
        }
        return result
    }

    // 全ダイスを回転開始
    private func startAllDice() {
        hasStarted = true

        for i in 0..<3 {
            isSpinning[i] = true
            diceNumbers[i] = Int.random(in: 1...6)

            // 高速で数字を変更
            spinTimers[i] = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                diceNumbers[i] = Int.random(in: 1...6)
            }
        }
    }

    // 個別のダイスを停止
    private func stopDice(_ index: Int) {
        isStopping[index] = true
        spinTimers[index]?.invalidate()

        // 徐々に遅くなりながら停止
        let delays: [Double] = [0.1, 0.15, 0.2, 0.3, 0.4, 0.5]
        var totalDelay = 0.0

        for delay in delays {
            totalDelay += delay
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                diceNumbers[index] = Int.random(in: 1...6)
            }
        }

        // 最終停止
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.3) {
            isSpinning[index] = false
            isStopping[index] = false
        }
    }
}

#Preview {
    ContentView()
}
