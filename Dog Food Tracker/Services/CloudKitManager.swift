import CloudKit
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let container = CKContainer(identifier: "iCloud.paulb71.DogFoodTracker")
    private let database: CKDatabase
    private var sharedZone: CKRecordZone?
    
    @Published var feedingRecords: [FeedingRecord] = []
    @Published var shareRecord: CKShare?
    @Published var isSharing = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isInitialized = false
    @Published var isLoading = false
    
    private init() {
        self.database = container.privateCloudDatabase
        Task {
            do {
                await checkAuthentication()
                if isAuthenticated {
                    try await setupSharedZone()
                    await validateCloudKitConfiguration()
                    try await fetchRecentRecords()
                }
                isInitialized = true
            } catch {
                print("❌ Setup error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isInitialized = true
            }
        }
    }
    
    private func setupSharedZone() async throws {
        print("Setting up shared zone...")
        let zoneName = "SharedFeedingZone"
        let zone = CKRecordZone(zoneName: zoneName)
        
        // First try to fetch existing zone
        do {
            let zones = try await database.allRecordZones()
            if let existingZone = zones.first(where: { $0.zoneID.zoneName == zoneName }) {
                self.sharedZone = existingZone
                print("✅ Found existing shared zone")
                
                // Create a new share record if needed
                if self.shareRecord == nil {
                    print("Creating share record...")
                    let shareRecord = CKShare(recordZoneID: existingZone.zoneID)
                    shareRecord[CKShare.SystemFieldKey.title] = "Dog Feeding Records"
                    
                    do {
                        let savedRecord = try await database.save(shareRecord)
                        if let savedShare = savedRecord as? CKShare {
                            self.shareRecord = savedShare
                            print("✅ Share record created successfully")
                        }
                    } catch let error as CKError where error.code == .serverRecordChanged {
                        // Share record already exists, this is fine
                        print("ℹ️ Share record already exists")
                    } catch {
                        print("⚠️ Non-critical error creating share: \(error.localizedDescription)")
                    }
                }
            } else {
                // Create new zone
                print("Creating shared zone...")
                _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
                self.sharedZone = zone
                print("✅ Shared zone created successfully")
                
                // Create initial share record
                let shareRecord = CKShare(recordZoneID: zone.zoneID)
                shareRecord[CKShare.SystemFieldKey.title] = "Dog Feeding Records"
                
                let savedRecord = try await database.save(shareRecord)
                if let savedShare = savedRecord as? CKShare {
                    self.shareRecord = savedShare
                    print("✅ Share record created successfully")
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create share record"])
                }
            }
        } catch {
            print("❌ Error in setupSharedZone: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func validateCloudKitConfiguration() async {
        print("🔍 Validating CloudKit Configuration...")
        print("📦 Container Identifier: \(container.containerIdentifier ?? "nil")")
        
        do {
            let accountStatus = try await container.accountStatus()
            print("👤 Account Status: \(accountStatus)")
            
            switch accountStatus {
            case .available:
                print("✅ iCloud account is available")
                // Try to get the user record ID to confirm authentication
                let userRecordID = try await container.userRecordID()
                print("✅ User Record ID: \(userRecordID.recordName)")
            case .noAccount:
                print("❌ No iCloud account found")
            case .restricted:
                print("❌ iCloud account is restricted")
            case .couldNotDetermine:
                print("❌ Could not determine iCloud account status")
            case .temporarilyUnavailable:
                print("❌ iCloud account is temporarily unavailable")
            @unknown default:
                print("❌ Unknown iCloud account status")
            }
            
            // Check if we can access the zone
            if let zone = sharedZone {
                print("🔄 Testing zone access...")
                let testQuery = CKQuery(recordType: "FeedingRecord", predicate: NSPredicate(value: true))
                testQuery.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                
                do {
                    let (results, _) = try await database.records(matching: testQuery, inZoneWith: zone.zoneID, resultsLimit: 1)
                    print("✅ Zone access successful")
                    print("ℹ️ Found \(results.count) records in zone")
                } catch let dbError as CKError {
                    print("❌ Zone access failed")
                    printDetailedCKError(dbError)
                }
            } else {
                print("⚠️ No shared zone available during validation")
            }
            
        } catch let error as CKError {
            print("❌ CloudKit Configuration Error")
            printDetailedCKError(error)
        } catch {
            print("❌ General Error: \(error.localizedDescription)")
        }
    }
    
    private func printDetailedCKError(_ error: CKError) {
        print("🚫 Error Code: \(error.code.rawValue)")
        print("📝 Description: \(error.localizedDescription)")
        
        if let retryAfter = error.retryAfterSeconds {
            print("⏰ Retry After: \(retryAfter) seconds")
        }
        
        // Print any partial errors
        if let partialErrors = error.partialErrorsByItemID {
            print("🔍 Partial Errors:")
            partialErrors.forEach { (key, value) in
                print("  - Item \(key): \(value.localizedDescription)")
            }
        }
        
        // Print additional error info
        switch error.code {
        case .badContainer:
            print("❌ Bad Container Error: The specified container is invalid or not accessible")
            print("💡 Tip: Verify the container identifier in Xcode capabilities matches exactly")
        case .notAuthenticated:
            print("❌ Authentication Error: User is not authenticated with iCloud")
            print("💡 Tip: Check if user is signed into iCloud on the device")
        case .permissionFailure:
            print("❌ Permission Error: The app doesn't have required permissions")
            print("💡 Tip: Verify CloudKit capability is enabled in Xcode")
        case .networkFailure:
            print("❌ Network Error: Unable to connect to iCloud")
            print("💡 Tip: Check internet connection and try again")
        default:
            print("❌ Other Error: \(error.code)")
        }
    }
    
    private func checkAuthentication() async {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                isAuthenticated = true
                print("✅ iCloud account available")
            case .noAccount:
                isAuthenticated = false
                print("❌ No iCloud account. Please sign in to iCloud in Settings")
            case .restricted:
                isAuthenticated = false
                print("❌ iCloud account restricted")
            case .couldNotDetermine:
                isAuthenticated = false
                print("❌ Could not determine iCloud account status")
            case .temporarilyUnavailable:
                isAuthenticated = false
                print("❌ iCloud account temporarily unavailable")
            @unknown default:
                isAuthenticated = false
                print("❌ Unknown iCloud account status")
            }
        } catch {
            isAuthenticated = false
            print("❌ Error checking iCloud account status: \(error.localizedDescription)")
        }
    }
    
    func saveFeedingRecord(_ record: FeedingRecord) async throws {
        guard isAuthenticated else {
            throw NSError(domain: "", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud to use this feature"])
        }
        guard let zone = sharedZone else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shared zone not setup"])
        }
        
        print("📝 Attempting to save record...")
        print("  - personName: \(record.personName)")
        print("  - petName: \(record.petName)")
        print("  - timestamp: \(record.timestamp)")
        
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zone.zoneID)
        let ckRecord = CKRecord(recordType: "FeedingRecord", recordID: recordID)
        ckRecord["personName"] = record.personName as CKRecordValue
        ckRecord["petName"] = record.petName as CKRecordValue
        ckRecord["timestamp"] = record.timestamp as CKRecordValue
        
        do {
            let savedRecord = try await database.save(ckRecord)
            print("✅ Successfully saved record with ID: \(savedRecord.recordID.recordName)")
            print("  - Saved personName: \(savedRecord["personName"] as? String ?? "nil")")
            print("  - Saved petName: \(savedRecord["petName"] as? String ?? "nil")")
            print("  - Saved timestamp: \(savedRecord["timestamp"] as? Date ?? Date())")
            
            // Create new record from saved data
            let newRecord = FeedingRecord(
                id: savedRecord.recordID.recordName,
                personName: savedRecord["personName"] as? String ?? "",
                petName: savedRecord["petName"] as? String ?? "",
                timestamp: savedRecord["timestamp"] as? Date ?? Date()
            )
            
            // Add the new record to the beginning of the array
            await MainActor.run {
                feedingRecords.insert(newRecord, at: 0)
                // Keep only the most recent 5 records
                if feedingRecords.count > 5 {
                    feedingRecords = Array(feedingRecords.prefix(5))
                }
            }
            
        } catch {
            print("❌ Detailed save error: \(error.localizedDescription)")
            if let ckError = error as? CKError {
                printDetailedCKError(ckError)
            }
            throw error
        }
    }
    
    func fetchRecentRecords() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard isAuthenticated else {
            throw NSError(domain: "", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud to use this feature"])
        }
        guard let zone = sharedZone else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shared zone not setup"])
        }
        
        print("📥 Attempting to fetch records...")
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        let query = CKQuery(recordType: "FeedingRecord", predicate: NSPredicate(value: true))
        query.sortDescriptors = [sort]
        
        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zone.zoneID, resultsLimit: 5)
            print("📊 Found \(results.count) records in database")
            
            var processedRecords: [FeedingRecord] = []
            
            for record in results {
                do {
                    let ckRecord = try record.1.get()
                    print("🔍 Processing record: \(ckRecord.recordID.recordName)")
                    print("  - personName: \(String(describing: ckRecord["personName"]))")
                    print("  - petName: \(String(describing: ckRecord["petName"]))")
                    print("  - timestamp: \(String(describing: ckRecord["timestamp"]))")
                    
                    let feedingRecord = FeedingRecord(
                        id: ckRecord.recordID.recordName,
                        personName: ckRecord["personName"] as? String ?? "",
                        petName: ckRecord["petName"] as? String ?? "",
                        timestamp: ckRecord["timestamp"] as? Date ?? Date()
                    )
                    processedRecords.append(feedingRecord)
                    print("✅ Successfully processed record")
                } catch {
                    print("❌ Failed to process record: \(error.localizedDescription)")
                }
            }
            
            print("📱 Setting feedingRecords with \(processedRecords.count) records")
            self.feedingRecords = processedRecords
            
        } catch {
            print("❌ Detailed fetch error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func showShareSheet() {
        isSharing = true
    }
    
    func getSharingController() -> UICloudSharingController? {
        guard let share = shareRecord else { return nil }
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite]
        return controller
    }
    
    func deleteAllRecords() async throws {
        guard isAuthenticated else {
            throw NSError(domain: "", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud to use this feature"])
        }
        guard let zone = sharedZone else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shared zone not setup"])
        }
        
        print("🗑️ Attempting to delete all records...")
        let query = CKQuery(recordType: "FeedingRecord", predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zone.zoneID)
            print("📊 Found \(results.count) records to delete")
            
            for record in results {
                do {
                    let recordID = try record.1.get().recordID
                    print("🗑️ Deleting record: \(recordID.recordName)")
                    try await database.deleteRecord(withID: recordID)
                    print("✅ Successfully deleted record")
                } catch {
                    print("❌ Failed to delete record: \(error.localizedDescription)")
                }
            }
            
            // Clear local records
            feedingRecords = []
            print("✅ All records deleted")
            
        } catch {
            print("❌ Delete error: \(error.localizedDescription)")
            throw error
        }
    }
} 