import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "waveform")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("BitChord")
                    .font(.largeTitle.bold())
                Text("iOS host is ready")
                    .foregroundStyle(.secondary)
                Text("The shared KMP data layer is being connected to the native iOS playback and UI services.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("BitChord")
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
