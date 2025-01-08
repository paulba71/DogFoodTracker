import Foundation

@MainActor
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var petName: String {
        didSet {
            UserDefaults.standard.set(petName, forKey: "petName")
        }
    }
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.petName = UserDefaults.standard.string(forKey: "petName") ?? ""
    }
} 