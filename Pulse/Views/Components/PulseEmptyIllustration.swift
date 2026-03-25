import SwiftUI

/// A warm, rose-toned illustration for Pulse empty states.
struct PulseEmptyIllustration: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 300

            // Soft background glow
            let glowGradient = Gradient(colors: [
                Theme.Colors.softBlush.opacity(0.4),
                Theme.Colors.softBlush.opacity(0)
            ])
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - 100 * scale,
                    y: center.y - 100 * scale,
                    width: 200 * scale,
                    height: 200 * scale
                )),
                with: .radialGradient(
                    glowGradient,
                    center: center,
                    startRadius: 0,
                    endRadius: 100 * scale
                )
            )

            // Decorative circles (warm tones)
            let circles: [(CGPoint, CGFloat, Color)] = [
                (CGPoint(x: center.x - 60 * scale, y: center.y - 40 * scale), 25 * scale, Theme.Colors.mutedRose.opacity(0.15)),
                (CGPoint(x: center.x + 70 * scale, y: center.y - 30 * scale), 18 * scale, Theme.Colors.dustyRose.opacity(0.2)),
                (CGPoint(x: center.x - 30 * scale, y: center.y + 50 * scale), 20 * scale, Theme.Colors.gentleGold.opacity(0.15)),
                (CGPoint(x: center.x + 50 * scale, y: center.y + 60 * scale), 15 * scale, Theme.Colors.calmSage.opacity(0.15)),
                (CGPoint(x: center.x, y: center.y), 12 * scale, Theme.Colors.mutedRose.opacity(0.2)),
            ]

            for (pos, radius, color) in circles {
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(path, with: .color(color))
            }

            // Heart motif
            let heartCenter = CGPoint(x: center.x, y: center.y - 10 * scale)
            let heartScale = 35 * scale
            drawHeart(context: context, center: heartCenter, scale: heartScale, color: Theme.Colors.mutedRose.opacity(0.3))

            // Pulse line (simplified heartbeat)
            let pulseY = center.y + 50 * scale
            let pulseWidth: CGFloat = 160 * scale
            let pulseStart = CGPoint(x: center.x - pulseWidth / 2, y: pulseY)

            var pulsePath = Path()
            pulsePath.move(to: CGPoint(x: pulseStart.x, y: pulseY))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth * 0.3, y: pulseY))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth * 0.4, y: pulseY - 25 * scale))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth * 0.5, y: pulseY + 20 * scale))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth * 0.6, y: pulseY - 15 * scale))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth * 0.7, y: pulseY))
            pulsePath.addLine(to: CGPoint(x: pulseStart.x + pulseWidth, y: pulseY))

            context.stroke(pulsePath, with: .color(Theme.Colors.dustyRose.opacity(0.4)), lineWidth: 2 * scale)

            // Small dots (warmth dots)
            let dots: [(CGPoint, CGFloat)] = [
                (CGPoint(x: 40 * scale, y: 60 * scale), 4 * scale),
                (CGPoint(x: 260 * scale, y: 80 * scale), 3 * scale),
                (CGPoint(x: 30 * scale, y: 240 * scale), 3 * scale),
                (CGPoint(x: 270 * scale, y: 220 * scale), 4 * scale),
                (CGPoint(x: 150 * scale, y: 25 * scale), 3 * scale),
            ]
            for (pos, radius) in dots {
                var dotPath = Path()
                dotPath.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(dotPath, with: .color(Theme.Colors.mutedRose.opacity(0.2)))
            }
        }
        .frame(width: size, height: size)
    }

    private func drawHeart(context: GraphicsContext, center: CGPoint, scale: CGFloat, color: Color) {
        let path = heartPath(center: center, scale: scale)
        context.fill(path, with: .color(color))
    }

    private func heartPath(center: CGPoint, scale: CGFloat) -> Path {
        var path = Path()
        let s = scale * 0.06

        // Heart using bezier curves
        path.move(to: CGPoint(x: center.x, y: center.y + 8 * s))

        // Left curve
        path.addCurve(
            to: CGPoint(x: center.x - 16 * s, y: center.y - 8 * s),
            control1: CGPoint(x: center.x - 8 * s, y: center.y + 8 * s),
            control2: CGPoint(x: center.x - 16 * s, y: center.y + 4 * s)
        )

        // Top left bump
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - 14 * s),
            control1: CGPoint(x: center.x - 16 * s, y: center.y - 8 * s),
            control2: CGPoint(x: center.x - 8 * s, y: center.y - 14 * s)
        )

        // Top right bump
        path.addCurve(
            to: CGPoint(x: center.x + 16 * s, y: center.y - 8 * s),
            control1: CGPoint(x: center.x + 8 * s, y: center.y - 14 * s),
            control2: CGPoint(x: center.x + 16 * s, y: center.y - 8 * s)
        )

        // Right curve
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + 8 * s),
            control1: CGPoint(x: center.x + 16 * s, y: center.y + 4 * s),
            control2: CGPoint(x: center.x + 8 * s, y: center.y + 8 * s)
        )

        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Theme.Colors.cream.ignoresSafeArea()
        PulseEmptyIllustration(size: 220)
    }
}
