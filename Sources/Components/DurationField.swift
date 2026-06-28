import SwiftUI

/// Minutes + seconds entry bound to a total-seconds value.
struct DurationField: View {
    @Binding var seconds: Int

    var body: some View {
        HStack {
            Text("Length")
            Spacer()
            numberField(
                placeholder: "min",
                get: { seconds / 60 },
                set: { seconds = max(0, $0) * 60 + (seconds % 60) }
            )
            Text("m").foregroundStyle(.secondary)
            numberField(
                placeholder: "sec",
                get: { seconds % 60 },
                set: { seconds = (seconds / 60) * 60 + min(59, max(0, $0)) }
            )
            Text("s").foregroundStyle(.secondary)
        }
    }

    private func numberField(placeholder: String, get: @escaping () -> Int, set: @escaping (Int) -> Void) -> some View {
        TextField(placeholder, value: Binding(get: get, set: set), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 44)
    }
}
