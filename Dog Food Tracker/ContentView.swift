//
//  ContentView.swift
//  Dog Food Tracker
//
//  Created by Paul Barnes on 06/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userPrefs = UserPreferences.shared
    @StateObject private var cloudKit = CloudKitManager.shared
    @State private var isShowingSetup = false
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    
    // Timer for auto-refresh
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if userPrefs.userName.isEmpty {
            SetupView()
        } else {
            mainView
        }
    }
    
    private var mainView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Feed Button - Large, prominent primary action
                        Button(action: {
                            Task {
                                isSaving = true
                                do {
                                    let record = FeedingRecord(
                                        personName: userPrefs.userName,
                                        petName: userPrefs.petName
                                    )
                                    try await cloudKit.saveFeedingRecord(record)
                                } catch {
                                    print("❌ Error saving record: \(error)")
                                }
                                isSaving = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "bowl.fill")
                                    .font(.system(size: 24))
                                Text("Record Feeding")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60) // Larger than 44pt minimum
                            .background(Color.accentColor)
                            .cornerRadius(15)
                            .shadow(radius: 2, y: 1)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Recent Feedings Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Feedings")
                                    .font(.title2.bold())
                                Spacer()
                                // Clear button with prominent style
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 16))
                                        Text("Clear")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if cloudKit.feedingRecords.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bowl")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("No feedings recorded yet")
                                        .font(.system(size: 17)) // At least 11pt
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(cloudKit.feedingRecords) { record in
                                        FeedingRecordView(record: record)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .refreshable {
                    await refreshRecords()
                }
            }
            .navigationTitle("\(userPrefs.petName)'s Feeding Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        cloudKit.showShareSheet()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17))
                            .frame(width: 44, height: 44) // 44pt minimum
                    }
                }
            }
        }
        .task {
            // Wait for CloudKit to be initialized before fetching
            while !cloudKit.isInitialized {
                try? await Task.sleep(nanoseconds: 100_000_000) // Wait 0.1 seconds
            }
            print("🔄 Initial load - fetching records")
            await refreshRecords()
        }
        .onReceive(timer) { _ in
            // Only refresh if initialized
            if cloudKit.isInitialized {
                print("⏰ Auto-refresh triggered")
                Task {
                    await refreshRecords()
                }
            }
        }
        .sheet(isPresented: $cloudKit.isSharing) {
            if cloudKit.shareRecord != nil {
                ShareViewController(cloudKit: cloudKit)
            }
        }
        .alert("Clear All Feedings?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    try? await cloudKit.deleteAllRecords()
                    await refreshRecords()
                }
            }
        } message: {
            Text("This will permanently delete all feeding records. This action cannot be undone.")
        }
    }
    
    // Helper function to refresh records
    private func refreshRecords() async {
        do {
            try await cloudKit.fetchRecentRecords()
            print("✅ Refresh completed")
            print("📱 Current feedingRecords count: \(cloudKit.feedingRecords.count)")
        } catch {
            print("❌ Refresh error: \(error)")
        }
    }
}

// Separate view for feeding records
struct FeedingRecordView: View {
    let record: FeedingRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(record.personName)")
                        .font(.headline)
                    Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "bowl.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
