import SwiftUI

struct ContentView: View {
    // 3つのダイスの状態
    @State private var scrollOffsets: [CGFloat] = [0, 0, 0]
    @State private var isSpinning: [Bool] = [false, false, false]
    @State private var isStopping: [Bool] = [false, false, false]
    @State private var spinTimers: [Timer?] = [nil, nil, nil]
    @State private var hasStarted = false
    @State private var spinSpeeds: [CGFloat] = [0, 0, 0]

    private let itemHeight: CGFloat = 50
    private let visibleItems = 5

    var body: some View {
        VStack {
            Spacer()

            // 3つのダイスを横に並べる
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { index in
                    VStack {
                        // スロットマシン風の数字表示
                        slotReelView(for: index)
                            .frame(width: 80, height: CGFloat(visibleItems) * itemHeight)
                            .clipped()

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

    // スロットリールの表示
    @ViewBuilder
    private func slotReelView(for index: Int) -> some View {
        let offset = scrollOffsets[index]

        GeometryReader { geometry in
            let centerY = geometry.size.height / 2

            ZStack {
                // 十分な数の数字を表示（上下にバッファ）
                ForEach(-10..<10, id: \.self) { i in
                    let number = wrapNumber(Int(offset / itemHeight) + i + 1)
                    let baseY = CGFloat(i) * itemHeight - offset.truncatingRemainder(dividingBy: itemHeight)
                    let itemCenterY = baseY + itemHeight / 2
                    let distanceFromCenter = abs(itemCenterY - centerY)
                    let maxDistance = centerY + itemHeight

                    // 中央からの距離に応じてスケールと透明度を調整
                    let scale = max(0.5, 1.0 - (distanceFromCenter / maxDistance) * 0.5)
                    let opacity = max(0.1, 1.0 - (distanceFromCenter / maxDistance) * 0.9)

                    Text("\(number)")
                        .font(.system(size: 44, weight: distanceFromCenter < itemHeight / 2 ? .bold : .medium))
                        .scaleEffect(scale)
                        .opacity(hasStarted ? opacity : 0.3)
                        .position(x: geometry.size.width / 2, y: baseY + itemHeight / 2)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            // 中央のハイライト
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .frame(height: itemHeight)
        )
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
            // 各リールに少し異なる速度を設定
            spinSpeeds[i] = CGFloat.random(in: 15...20)

            // 滑らかにスクロール
            spinTimers[i] = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
                scrollOffsets[i] += spinSpeeds[i]
            }
        }
    }

    // 個別のダイスを停止
    private func stopDice(_ index: Int) {
        isStopping[index] = true

        // 徐々に減速
        let decelerationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            spinSpeeds[index] *= 0.97

            scrollOffsets[index] += spinSpeeds[index]

            // 十分に遅くなったら停止
            if spinSpeeds[index] < 0.5 {
                timer.invalidate()
                spinTimers[index]?.invalidate()

                // 最も近い数字にスナップ
                let targetOffset = round(scrollOffsets[index] / itemHeight) * itemHeight
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scrollOffsets[index] = targetOffset
                }

                isSpinning[index] = false
                isStopping[index] = false
            }
        }

        // 元のタイマーを停止
        spinTimers[index]?.invalidate()
        spinTimers[index] = decelerationTimer
    }

    // 現在の数字を取得
    private func currentNumber(for index: Int) -> Int {
        return wrapNumber(Int(round(scrollOffsets[index] / itemHeight)) + 1)
    }
}

#Preview {
    ContentView()
}
