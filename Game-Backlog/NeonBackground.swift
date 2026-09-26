import SwiftUI

// The app's "neon night" background: a dark gradient with two soft glows.
// Use it on any screen with .background(NeonBackground())

struct NeonBackground: View {
    var body: some View {
        ZStack {
            // Base: deep navy fading to black
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.05, blue: 0.16), .black],
                startPoint: .top,
                endPoint: .bottom
            )

            // Purple glow, top-left (a circle blurred into soft light)
            Circle()
                .fill(Color.purple.opacity(0.7))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -130, y: -260)

            // Blue glow, bottom-right
            Circle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 320, height: 320)
                .blur(radius: 130)
                .offset(x: 150, y: 320)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NeonBackground()
}
