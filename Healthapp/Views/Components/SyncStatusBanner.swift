//
//  SyncStatusBanner.swift
//  Netfuel
//
//  Banner showing offline sync status
//

import SwiftUI

/// Banner showing sync status and offline queue
struct SyncStatusBanner: View {
    @ObservedObject var syncManager = SyncManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                // Offline banner
                OfflineBanner(queuedCount: syncManager.queuedActionsCount)
            } else if syncManager.isSyncing {
                // Syncing banner
                SyncingBanner(progress: syncManager.syncProgress)
            } else if syncManager.hasQueuedActions {
                // Ready to sync banner
                ReadyToSyncBanner(queuedCount: syncManager.queuedActionsCount) {
                    Task {
                        await syncManager.syncQueuedActions()
                    }
                }
            }
        }
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    let queuedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if queuedCount > 0 {
                    Text("\(queuedCount) action\(queuedCount == 1 ? "" : "s") queued")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.orange)
        .cornerRadius(12)
        .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Syncing Banner

struct SyncingBanner: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Syncing...")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("\(Int(progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.white)
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Ready to Sync Banner

struct ReadyToSyncBanner: View {
    let queuedCount: Int
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to Sync")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("\(queuedCount) action\(queuedCount == 1 ? "" : "s") pending")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Button {
                HapticFeedback.light()
                onSync()
            } label: {
                Text("Sync Now")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.green)
        .cornerRadius(12)
        .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Offline") {
    VStack {
        OfflineBanner(queuedCount: 3)
        Spacer()
    }
}

#Preview("Syncing") {
    VStack {
        SyncingBanner(progress: 0.65)
        Spacer()
    }
}

#Preview("Ready to Sync") {
    VStack {
        ReadyToSyncBanner(queuedCount: 5) {}
        Spacer()
    }
}
