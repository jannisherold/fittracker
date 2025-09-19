import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        Group {
            if isActive {
                ContentView()   // Deine eigentliche Start-View
            } else {
                ZStack {
                    Color.white.ignoresSafeArea() // Hintergrundfarbe
                    Text("progress.")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            // Nach 2 Sekunden zur ContentView wechseln
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}
