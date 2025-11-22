import SwiftUI

struct ContentView: View {
    @State private var currentNumber: Int?
    @State private var history: [Int] = []

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
            Button("ダイスを振る") {
                rollDice()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
        }
    }

    private func rollDice() {
        // 現在の数字があれば履歴に追加
        if let current = currentNumber {
            history.append(current)
        }
        // 新しい数字を生成
        currentNumber = Int.random(in: 1...6)
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
