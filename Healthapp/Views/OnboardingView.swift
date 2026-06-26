//
//  OnboardingView.swift
//  Netfuel
//
//  Main onboarding container with page navigation
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingCompleted: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar with Progress
                topBar

                // Page Content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingPage.allCases, id: \.self) { page in
                        pageView(for: page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentPage)

                // Bottom Controls
                bottomControls
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                // Mark onboarding as complete - this will trigger ContentView to switch to main app
                print("📱 Onboarding complete, updating state...")
                isOnboardingCompleted = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Back Button
                if viewModel.canGoBack {
                    Button {
                        withAnimation {
                            viewModel.goToPreviousPage()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Skip Button (only on skippable pages)
                if viewModel.canSkip {
                    Button {
                        withAnimation {
                            viewModel.skipPage()
                        }
                    } label: {
                        Text("Skip")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                } else {
                    Spacer()
                        .frame(width: 60)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Progress Bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
                .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Page Content

    @ViewBuilder
    private func pageView(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            WelcomePageView()

        case .features:
            FeaturesPageView()

        case .profileSetup:
            ProfileSetupPageView(
                onboardingViewModel: viewModel,
                appState: appState
            )

        case .goalsSetup:
            GoalsSetupPageView(onboardingViewModel: viewModel)

        case .stravaConnection:
            StravaConnectionPageView(onboardingViewModel: viewModel)

        case .permissions:
            PermissionsPageView(onboardingViewModel: viewModel)

        case .ready:
            ReadyPageView()
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page Indicator Dots
            pageIndicator

            // Next/Get Started Button
            nextButton
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingPage.allCases, id: \.self) { page in
                Circle()
                    .fill(viewModel.currentPage == page ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: viewModel.currentPage)
            }
        }
    }

    private var nextButton: some View {
        Button {
            handleNextAction()
        } label: {
            HStack {
                Text(buttonTitle)
                    .fontWeight(.semibold)

                if viewModel.currentPage != .ready {
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(buttonBackgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!canProceed)
        .opacity(canProceed ? 1.0 : 0.6)
    }

    // MARK: - Helper Properties

    private var buttonTitle: String {
        switch viewModel.currentPage {
        case .ready:
            return "Get Started"
        default:
            return "Continue"
        }
    }

    private var buttonBackgroundColor: Color {
        switch viewModel.currentPage {
        case .ready:
            return Color.green
        default:
            return Color.blue
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentPage {
        case .profileSetup:
            return viewModel.isProfileSetupComplete
        case .goalsSetup, .ready:
            return true
        default:
            return viewModel.canGoNext
        }
    }

    // MARK: - Actions

    private func handleNextAction() {
        switch viewModel.currentPage {
        case .ready:
            // Complete onboarding and dismiss
            viewModel.completeOnboarding()
        default:
            // Go to next page
            withAnimation {
                viewModel.goToNextPage()
            }
        }
    }
}

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
        .environmentObject(AppState())
}
