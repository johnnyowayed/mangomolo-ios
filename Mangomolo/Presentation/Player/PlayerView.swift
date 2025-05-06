// Player view placeholder
import SwiftUI

struct PlayerView: View {
    let mediaItem: MediaItem
    let isSubscribed: Bool

    var body: some View {
        FullScreenPlayerWrapper(
            mediaURL: mediaItem.mediaURL,
            isSubscribed: isSubscribed
        )
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.all)
    }
}

struct FullScreenPlayerWrapper: UIViewControllerRepresentable {
    let mediaURL: URL
    let isSubscribed: Bool
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        let playerVC = PlayerViewController(contentURL: mediaURL, isSubscribed: isSubscribed)
        playerVC.onDismiss = {
            dismiss()
        }
        playerVC.modalPresentationStyle = .fullScreen
        return playerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension EnvironmentValues {
    var dismiss: () -> Void {
        { presentationMode.wrappedValue.dismiss() }
    }
}
