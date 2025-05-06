// MediaItem model
import Foundation

struct MediaItem: Identifiable {
    enum Orientation {
        case portrait
        case landscape
    }

    let id: UUID = UUID()
    let title: String
    let imageURL: URL
    let mediaURL: URL
    let orientation: Orientation
}
