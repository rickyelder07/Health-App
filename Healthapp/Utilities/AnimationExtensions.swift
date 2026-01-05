//
//  AnimationExtensions.swift
//  Health App
//
//  Animation utilities and view transitions
//

import SwiftUI

// MARK: - Custom Animations

extension Animation {
    /// Smooth spring animation
    static var smoothSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }

    /// Bouncy spring animation
    static var bouncySpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.6)
    }

    /// Gentle ease animation
    static var gentleEase: Animation {
        .easeInOut(duration: 0.3)
    }

    /// Quick fade animation
    static var quickFade: Animation {
        .easeIn(duration: 0.2)
    }
}

// MARK: - View Transition Extensions

extension AnyTransition {
    /// Scale and fade transition
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }

    /// Slide from bottom with fade
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// Slide from top with fade
    static var slideDown: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }

    /// Slide from leading with fade
    static var slideLeading: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }

    /// Slide from trailing with fade
    static var slideTrailing: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }

    /// Pop animation (scale up with bounce)
    static var pop: AnyTransition {
        .scale(scale: 0.1).combined(with: .opacity)
    }
}

// MARK: - Animated Card Modifiers

struct CardAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.smoothSpring.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Animate card appearance with delay
    func cardAppearance(delay: Double = 0) -> some View {
        modifier(CardAppearModifier(delay: delay))
    }
}

// MARK: - Shake Animation

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    /// Shake the view (useful for errors)
    func shake(times: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(times)))
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Add a pulsing animation
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Loading Spinner

struct LoadingSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [.blue, .blue.opacity(0.1)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 30, height: 30)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Progress Bar with Animation

struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.2))
                    .frame(height: height)

                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress, height: height)
                    .animation(.smoothSpring, value: animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            withAnimation(.smoothSpring) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Floating Action Button Animation

struct FloatingButtonModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .shadow(color: .black.opacity(isPressed ? 0.2 : 0.3), radius: isPressed ? 5 : 10, y: isPressed ? 3 : 6)
            .animation(.smoothSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// Add floating action button animation
    func floatingButton() -> some View {
        modifier(FloatingButtonModifier())
    }
}

// MARK: - Conditional Animation

extension View {
    /// Apply animation conditionally
    func conditionalAnimation<V: Equatable>(_ animation: Animation?, value: V, condition: Bool) -> some View {
        if condition {
            return AnyView(self.animation(animation, value: value))
        } else {
            return AnyView(self)
        }
    }

    /// Apply animation that respects accessibility settings
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        let shouldAnimate = !AccessibilityUtility.isReduceMotionEnabled
        return conditionalAnimation(animation, value: value, condition: shouldAnimate)
    }
}

// MARK: - Slide In Modifier

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? offset : (edge == .trailing ? -offset : 0),
                y: edge == .top ? offset : (edge == .bottom ? -offset : 0)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.smoothSpring.delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

extension View {
    /// Slide in from edge
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - Rotate Animation

struct RotateModifier: ViewModifier {
    @State private var isRotating = false
    let duration: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    isRotating = true
                }
            }
    }
}

extension View {
    /// Continuously rotate
    func rotate(duration: Double = 2.0) -> some View {
        modifier(RotateModifier(duration: duration))
    }
}

#Preview("Animated Progress") {
    VStack(spacing: 20) {
        AnimatedProgressBar(progress: 0.3, color: .red, height: 8)
        AnimatedProgressBar(progress: 0.6, color: .blue, height: 12)
        AnimatedProgressBar(progress: 0.9, color: .green, height: 16)
    }
    .padding()
}

#Preview("Loading Spinner") {
    LoadingSpinner()
}
