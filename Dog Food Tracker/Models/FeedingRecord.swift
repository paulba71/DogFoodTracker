import Foundation
import CloudKit

struct FeedingRecord: Identifiable, Codable {
    let id: String
    let personName: String
    let petName: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, 
         personName: String, 
         petName: String,
         timestamp: Date = Date()) {
        self.id = id
        self.personName = personName
        self.petName = petName
        self.timestamp = timestamp
    }
} 