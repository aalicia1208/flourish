//
//  flourishApp.swift
//  flourish
//
//  Created by Alicia Yee on 8/3/25.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth

@main
struct flourishApp: App {
    init() {
        FirebaseApp.configure()
        func setupAnonymousUser() {
            if Auth.auth().currentUser == nil {
                Auth.auth().signInAnonymously { (authResult, error) in
                    if let error = error {
                        print("Error signing in anonymously: \(error.localizedDescription)")
                    } else {
                        print("Successfully signed in anonymously! User ID: \(authResult?.user.uid ?? "N/A")")
                    }
                }
            } else {
                print("User already signed in. User ID: \(Auth.auth().currentUser?.uid ?? "N/A")")
            }
        }
        setupAnonymousUser()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
