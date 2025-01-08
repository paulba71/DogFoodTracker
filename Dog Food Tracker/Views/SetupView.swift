import SwiftUI

struct SetupView: View {
    @StateObject private var userPrefs = UserPreferences.shared
    @State private var tempUserName = ""
    @State private var tempPetName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        DogWelcomeSymbol()
                            .frame(width: 120, height: 120)
                        
                        Text("Welcome to\nDog Feeding Tracker")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Text("Keep track of when your furry friend has been fed")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Your Name", systemImage: "person.fill")
                                .font(.headline)
                            
                            TextField("Enter your name", text: $tempUserName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 17))
                                .frame(height: 44)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Dog's Name", systemImage: "pawprint.fill")
                                .font(.headline)
                            
                            TextField("Enter dog's name", text: $tempPetName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 17))
                                .frame(height: 44)
                                .autocapitalization(.words)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        guard !tempUserName.isEmpty && !tempPetName.isEmpty else { return }
                        userPrefs.userName = tempUserName
                        userPrefs.petName = tempPetName
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.headline)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            !tempUserName.isEmpty && !tempPetName.isEmpty ?
                            Color.accentColor : Color.gray
                        )
                        .cornerRadius(16)
                        .shadow(radius: 2, y: 1)
                    }
                    .disabled(tempUserName.isEmpty || tempPetName.isEmpty)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct DogWelcomeSymbol: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.accentColor.opacity(0.1))
            
            // Dog symbols composition
            VStack(spacing: -5) {
                HStack(spacing: 3) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(-30))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(30))
                }
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 50))
                
                HStack(spacing: 3) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(-30))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(30))
                }
            }
            .foregroundColor(.accentColor)
        }
    }
} 