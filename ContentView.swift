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
        // spinSpeedsはフレームあたりのピクセル数なので、秒あたりに変換（60fps）
        let v0 = spinSpeeds[index] * 60.0 // ピクセル/秒

        // 速度に応じた停止時間調整係数（100%→1.6倍、20%→0.7倍）
        let timeFactor = 0.7 + (speedMultiplier - 0.2) / 0.8 * 0.9

        // 目標位置を決定（現在位置から1〜2周先、時間調整係数を適用）
        let baseExtraItems = CGFloat(Int.random(in: 6...12))
        let extraItems = baseExtraItems * timeFactor
        let rawTarget = currentOffset + itemHeight * extraItems
        let targetOffset = round(rawTarget / itemHeight) * itemHeight
        let totalDistance = targetOffset - currentOffset

        // 物理ベースの減速：等減速運動
        // d = v0^2 / (2*a) → a = v0^2 / (2*d)
        // 停止時間: t = v0 / a = 2*d / v0
        let deceleration = (v0 * v0) / (2.0 * totalDistance)
        let stopTime = v0 / deceleration
        let startTime = Date()

        // 等減速運動でアニメーション
        let decelerationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = CGFloat(Date().timeIntervalSince(startTime))

            if elapsed >= stopTime {
                // 完了
                timer.invalidate()
                scrollOffsets[index] = targetOffset
                isSpinning[index] = false
                isStopping[index] = false
            } else {
                // 等減速運動: x = x0 + v0*t - 0.5*a*t^2
                let position = currentOffset + v0 * elapsed - 0.5 * deceleration * elapsed * elapsed
                scrollOffsets[index] = position
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
