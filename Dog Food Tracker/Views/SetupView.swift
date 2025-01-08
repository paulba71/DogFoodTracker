import SwiftUI

struct SetupView: View {
    @StateObject private var userPrefs = UserPreferences.shared
    @State private var tempUserName = ""
    @State private var tempPetName = ""
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Welcome to Dog Feeding Tracker")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Please enter your details to get started")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                    TextField("Enter your name", text: $tempUserName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 17))
                        .frame(height: 44)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dog's Name")
                        .font(.headline)
                    TextField("Enter dog's name", text: $tempPetName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 17))
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                guard !tempUserName.isEmpty && !tempPetName.isEmpty else { return }
                userPrefs.userName = tempUserName
                userPrefs.petName = tempPetName
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(tempUserName.isEmpty || tempPetName.isEmpty)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
} 