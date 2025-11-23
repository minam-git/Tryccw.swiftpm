import SwiftUI

struct ContentView: View {
    // 3つのダイスの状態
    @State private var scrollOffsets: [CGFloat] = [0, 0, 0]
    @State private var isSpinning: [Bool] = [false, false, false]
    @State private var isStopping: [Bool] = [false, false, false]
    @State private var spinTimers: [Timer?] = [nil, nil, nil]
    @State private var hasStarted = false
    @State private var spinSpeeds: [CGFloat] = [0, 0, 0]
    @State private var speedMultiplier: Double = 1.0

    private let itemHeight: CGFloat = 50
    private let visibleItems = 5
    private let speedOptions: [Double] = [0.2, 0.4, 0.6, 0.8, 1.0]

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
            .disabled(isSpinning.contains(true))

            // 速度調整スライダー
            VStack(spacing: 8) {
                Text("速度: \(Int(speedMultiplier * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("20%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: $speedMultiplier,
                        in: 0.2...1.0,
                        step: 0.2
                    )
                    .frame(width: 200)

                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 16)
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
            // 各リールに少し異なる速度を設定（速度倍率を適用）
            let baseSpeed = CGFloat.random(in: 15...20)
            spinSpeeds[i] = baseSpeed * CGFloat(speedMultiplier)

            // 滑らかにスクロール
            spinTimers[i] = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
                scrollOffsets[i] += spinSpeeds[i]
            }
        }
    }

    // 個別のダイスを停止
    private func stopDice(_ index: Int) {
        isStopping[index] = true
        spinTimers[index]?.invalidate()

        let currentOffset = scrollOffsets[index]
        let currentSpeed = spinSpeeds[index]

        // 現在の速度から自然に減速して止まる距離を計算
        // easeOutCubicの初期速度 = totalDistance / duration * 3
        // よって duration = totalDistance * 3 / currentSpeed
        // 適切な減速時間になるよう距離を調整
        let duration: Double = 2.0
        // 現在の速度で2秒間かけて自然に止まる距離
        let naturalDistance = currentSpeed * CGFloat(duration) / 3.0

        // その距離を最も近い数字の位置に合わせる（少なくとも1周は回る）
        let minDistance = itemHeight * 6 // 最低1周
        let adjustedDistance = max(naturalDistance, minDistance)
        let rawTarget = currentOffset + adjustedDistance
        let targetOffset = round(rawTarget / itemHeight) * itemHeight

        // アニメーションのパラメータ
        let startOffset = currentOffset
        let totalDistance = targetOffset - startOffset
        // 実際の距離に合わせてdurationを再計算（初期速度が現在速度と一致するように）
        let adjustedDuration = Double(totalDistance) * 3.0 / Double(currentSpeed)
        let startTime = Date()

        // easeOutで滑らかに減速しながら目標位置へ
        let decelerationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / adjustedDuration, 1.0)

            // easeOutCubic: 最初は速く、最後はゆっくり
            let easedProgress = 1.0 - pow(1.0 - progress, 3)

            scrollOffsets[index] = startOffset + totalDistance * easedProgress

            // アニメーション完了
            if progress >= 1.0 {
                timer.invalidate()
                scrollOffsets[index] = targetOffset // 正確な位置に設定
                isSpinning[index] = false
                isStopping[index] = false
            }
        }

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
