import SwiftUI

// 紙吹雪のパーティクル
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let rotation: Double
    let size: CGFloat
}

struct ContentView: View {
    // 3つのダイスの状態
    @State private var scrollOffsets: [CGFloat] = [0, 0, 0]
    @State private var isSpinning: [Bool] = [false, false, false]
    @State private var isStopping: [Bool] = [false, false, false]
    @State private var spinTimers: [Timer?] = [nil, nil, nil]
    @State private var hasStarted = false
    @State private var spinSpeeds: [CGFloat] = [0, 0, 0]
    @State private var speedMultiplier: Double = 1.0

    // 各リールのランダムな数字の並び
    @State private var reelSequences: [[Int]] = [
        [1, 2, 3, 4, 5, 6].shuffled(),
        [1, 2, 3, 4, 5, 6].shuffled(),
        [1, 2, 3, 4, 5, 6].shuffled()
    ]

    // 演出用の状態
    @State private var isJackpot = false
    @State private var isReach = false
    @State private var reachReelIndex: Int? = nil
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var jackpotScale: CGFloat = 1.0
    @State private var jackpotOpacity: Double = 0.0
    @State private var winningLineCount: Int = 0  // 当たりライン数

    private let itemHeight: CGFloat = 50
    private let visibleItems = 5
    private let speedOptions: [Double] = [0.2, 0.4, 0.6, 0.8, 1.0]
    private let confettiColors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]

    // 5つの判定ライン定義
    // 各ラインは (リール0の行オフセット, リール1の行オフセット, リール2の行オフセット)
    // 行オフセット: -1=上段(行2), 0=中段(行3), 1=下段(行4)
    private let paylines: [(Int, Int, Int)] = [
        (-1, -1, -1),  // ライン1: 横上段
        (0, 0, 0),     // ライン2: 横中段
        (1, 1, 1),     // ライン3: 横下段
        (-1, 0, 1),    // ライン4: 斜め↘
        (1, 0, -1)     // ライン5: 斜め↗
    ]

    var body: some View {
        ZStack {
            // ゾロ目時の背景エフェクト
            if isJackpot {
                Color.yellow
                    .opacity(jackpotOpacity * 0.3)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: jackpotOpacity)
            }

            VStack {
                Spacer()

                // ゾロ目メッセージ
                if isJackpot {
                    VStack(spacing: 8) {
                        if winningLineCount >= 3 {
                            Text("🌟 SUPER JACKPOT! 🌟")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.purple)
                        } else if winningLineCount == 2 {
                            Text("✨ BIG JACKPOT! ✨")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.red)
                        } else {
                            Text("🎉 JACKPOT! 🎉")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        Text("\(winningLineCount)ライン当たり!")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .scaleEffect(jackpotScale)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: jackpotScale)
                    .padding(.bottom, 20)
                }

                // リーチメッセージ
                if isReach && !isJackpot {
                    Text("🔥 REACH! 🔥")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.bottom, 20)
                }

                // 3つのダイスを横に並べる
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { index in
                        VStack {
                            // スロットマシン風の数字表示
                            slotReelView(for: index)
                                .frame(width: 80, height: CGFloat(visibleItems) * itemHeight)
                                .clipped()
                                .overlay(
                                    // リーチ時のハイライト
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 3)
                                        .opacity(isReach && reachReelIndex == index && isSpinning[index] ? 1 : 0)
                                )

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

            // 紙吹雪
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 1.5)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(x: piece.x, y: piece.y)
            }
        }
    }

    // スロットリールの表示
    @ViewBuilder
    private func slotReelView(for index: Int) -> some View {
        let offset = scrollOffsets[index]
        let sequence = reelSequences[index]

        GeometryReader { geometry in
            let centerY = geometry.size.height / 2

            ZStack {
                // 十分な数の数字を表示（上下にバッファ）
                ForEach(-10..<10, id: \.self) { i in
                    let seqIndex = wrapIndex(Int(offset / itemHeight) + i, count: sequence.count)
                    let number = sequence[seqIndex]
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

    // インデックスを循環させる
    private func wrapIndex(_ n: Int, count: Int) -> Int {
        var result = n % count
        if result < 0 {
            result += count
        }
        return result
    }

    // 全ダイスを回転開始
    private func startAllDice() {
        hasStarted = true
        isJackpot = false
        isReach = false
        reachReelIndex = nil
        confettiPieces = []
        jackpotOpacity = 0

        // 各リールのシーケンスをシャッフル
        for i in 0..<3 {
            reelSequences[i] = [1, 2, 3, 4, 5, 6].shuffled()
        }

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
        var timeFactor = 0.7 + (speedMultiplier - 0.2) / 0.8 * 0.9

        // リーチ状態で最後のリールならゆっくり
        if isReach && reachReelIndex == index {
            timeFactor *= 2.5 // より長く回る
        }

        // 目標位置を決定（現在位置から1〜2周先、時間調整係数を適用）
        let baseExtraItems = CGFloat(Int.random(in: 6...12))
        let extraItems = baseExtraItems * timeFactor
        let rawTarget = currentOffset + itemHeight * extraItems
        let targetOffset = round(rawTarget / itemHeight) * itemHeight
        let totalDistance = targetOffset - currentOffset

        // 物理ベースの減速：等減速運動
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

                // 停止後の判定
                checkReachAndJackpot()
            } else {
                // 等減速運動: x = x0 + v0*t - 0.5*a*t^2
                let position = currentOffset + v0 * elapsed - 0.5 * deceleration * elapsed * elapsed
                scrollOffsets[index] = position
            }
        }

        spinTimers[index] = decelerationTimer
    }

    // リーチとゾロ目の判定（5ライン対応）
    private func checkReachAndJackpot() {
        let stoppedIndices = (0..<3).filter { !isSpinning[$0] }
        let spinningIndices = (0..<3).filter { isSpinning[$0] }

        // 全部停止した場合
        if stoppedIndices.count == 3 {
            // 各ラインをチェックして当たりライン数をカウント
            var winCount = 0
            for line in paylines {
                let numbers = getLineNumbers(line)
                // ゾロ目判定
                if numbers[0] == numbers[1] && numbers[1] == numbers[2] {
                    winCount += 1
                }
                // ストレート（連続）判定
                else if isStraight(numbers) {
                    winCount += 1
                }
            }

            if winCount > 0 {
                winningLineCount = winCount
                triggerJackpot()
            }

            isReach = false
            reachReelIndex = nil
        }
        // 2つ停止した場合
        else if stoppedIndices.count == 2 && spinningIndices.count == 1 {
            // いずれかのラインでリーチの可能性があるかチェック
            var hasReachPotential = false
            for line in paylines {
                if checkLineReach(line, stoppedIndices: stoppedIndices) {
                    hasReachPotential = true
                    break
                }
            }

            if hasReachPotential {
                isReach = true
                reachReelIndex = spinningIndices[0]
                slowDownReachReel(spinningIndices[0])
            }
        }
    }

    // 特定のラインでリーチの可能性があるかチェック
    private func checkLineReach(_ line: (Int, Int, Int), stoppedIndices: [Int]) -> Bool {
        let offsets = [line.0, line.1, line.2]

        // 停止したリールの数字を取得
        var stoppedNumbers: [Int] = []
        var spinningReelIndex: Int = -1

        for reelIndex in 0..<3 {
            if stoppedIndices.contains(reelIndex) {
                stoppedNumbers.append(getNumber(reelIndex: reelIndex, rowOffset: offsets[reelIndex]))
            } else {
                spinningReelIndex = reelIndex
            }
        }

        guard stoppedNumbers.count == 2 else { return false }

        // 2つが同じならリーチ
        if stoppedNumbers[0] == stoppedNumbers[1] {
            return true
        }

        // 連続の可能性チェック
        let sortedStoppedIndices = stoppedIndices.sorted()
        return canFormStraightForLine(sortedStoppedIndices, stoppedNumbers, offsets: offsets)
    }

    // ライン別の連続リーチ判定
    private func canFormStraightForLine(_ indices: [Int], _ numbers: [Int], offsets: [Int]) -> Bool {
        guard indices.count == 2 && numbers.count == 2 else { return false }

        let first = numbers[0]
        let second = numbers[1]

        // 停止しているリールの位置パターンで判定
        if indices == [0, 1] {
            if second - first == 1 && second + 1 <= 6 { return true }
            if first - second == 1 && second - 1 >= 1 { return true }
        }
        else if indices == [0, 2] {
            if second - first == 2 { return true }
            if first - second == 2 { return true }
        }
        else if indices == [1, 2] {
            if second - first == 1 && first - 1 >= 1 { return true }
            if first - second == 1 && first + 1 <= 6 { return true }
        }

        return false
    }

    // 3つの数字がストレート（連続）かどうか判定
    // 左から右へ昇順、または右から左へ降順（逆順）のみ
    private func isStraight(_ numbers: [Int]) -> Bool {
        guard numbers.count == 3 else { return false }

        // 昇順: 1,2,3 / 2,3,4 / 3,4,5 / 4,5,6
        if numbers[1] - numbers[0] == 1 && numbers[2] - numbers[1] == 1 {
            return true
        }

        // 降順: 6,5,4 / 5,4,3 / 4,3,2 / 3,2,1
        if numbers[0] - numbers[1] == 1 && numbers[1] - numbers[2] == 1 {
            return true
        }

        return false
    }

    // リーチ時に残りのリールを減速
    private func slowDownReachReel(_ index: Int) {
        spinSpeeds[index] *= 0.5 // 速度を半分に
    }

    // ゾロ目演出
    private func triggerJackpot() {
        isJackpot = true
        jackpotScale = 1.2
        jackpotOpacity = 1.0

        // 紙吹雪を生成
        startConfetti()

        // 数秒後に演出を終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                isJackpot = false
                jackpotOpacity = 0
                confettiPieces = []
            }
        }
    }

    // 紙吹雪アニメーション
    private func startConfetti() {
        // 紙吹雪を生成
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                color: confettiColors.randomElement()!,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 8...15)
            )
            confettiPieces.append(piece)
        }

        // アニメーション
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            if !isJackpot {
                timer.invalidate()
                return
            }

            for i in confettiPieces.indices {
                confettiPieces[i].y += CGFloat.random(in: 3...8)
                confettiPieces[i].x += CGFloat.random(in: -2...2)
            }

            // 画面外に出た紙吹雪を上に戻す
            for i in confettiPieces.indices {
                if confettiPieces[i].y > UIScreen.main.bounds.height + 20 {
                    confettiPieces[i].y = -20
                    confettiPieces[i].x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                }
            }
        }
    }

    // 現在の数字を取得（中央行）
    private func currentNumber(for index: Int) -> Int {
        return getNumber(reelIndex: index, rowOffset: 0)
    }

    // 指定した行オフセットの数字を取得
    // rowOffset: -1=上段, 0=中段, 1=下段
    private func getNumber(reelIndex: Int, rowOffset: Int) -> Int {
        let sequence = reelSequences[reelIndex]
        let baseIndex = Int(round(scrollOffsets[reelIndex] / itemHeight))
        let seqIndex = wrapIndex(baseIndex + rowOffset, count: sequence.count)
        return sequence[seqIndex]
    }

    // 指定したラインの3つの数字を取得
    private func getLineNumbers(_ line: (Int, Int, Int)) -> [Int] {
        return [
            getNumber(reelIndex: 0, rowOffset: line.0),
            getNumber(reelIndex: 1, rowOffset: line.1),
            getNumber(reelIndex: 2, rowOffset: line.2)
        ]
    }
}

#Preview {
    ContentView()
}
