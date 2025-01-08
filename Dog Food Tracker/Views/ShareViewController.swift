import SwiftUI
import CloudKit
import UIKit

struct ShareViewController: UIViewControllerRepresentable {
    let cloudKit: CloudKitManager
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = cloudKit.getSharingController() ?? UICloudSharingController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: ShareViewController
        
        init(_ parent: ShareViewController) {
            self.parent = parent
        }
        
        func cloudSharingController(_ ctr: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error.localizedDescription)")
        }
        
        func itemTitle(for ctr: UICloudSharingController) -> String? {
            return "Dog Feeding Records"
        }
    }
} 