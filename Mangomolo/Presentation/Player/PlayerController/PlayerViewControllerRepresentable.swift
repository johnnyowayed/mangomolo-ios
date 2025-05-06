//
//  PlayerViewControllerRepresentable.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 07/05/2025.
//

import SwiftUI

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let mediaURL: URL
    let isSubscribed: Bool
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PlayerViewController(contentURL: mediaURL, isSubscribed: isSubscribed)
        controller.onDismiss = {
            isPresented = false
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
