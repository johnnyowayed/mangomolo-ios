import Foundation

class HomeViewModel: ObservableObject {
    @Published var verticalItems: [MediaItem] = []
    @Published var horizontalItems: [MediaItem] = []
    @Published var isSubscribed: Bool = KeychainService.shared.loadSubscriptionStatus() {
        didSet {
            KeychainService.shared.saveSubscriptionStatus(isSubscribed)
        }
    }

    init() {
        loadMockData()
    }

    private func loadMockData() {
        // Replace with real API logic
        let sampleURL = URL(string: "https://via.placeholder.com/300")!
        let videoURL = URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!
        verticalItems = (1...10).map { _ in MediaItem(title: "Vertical \\($0)", imageURL: sampleURL, mediaURL: videoURL, orientation: .portrait) }
        horizontalItems = (1...10).map { _ in MediaItem(title: "Horizontal \\($0)", imageURL: sampleURL, mediaURL: videoURL, orientation: .landscape) }
    }
}
