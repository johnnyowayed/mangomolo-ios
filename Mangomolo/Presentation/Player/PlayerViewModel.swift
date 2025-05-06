//
//  PlayerViewModel.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 05/05/2025.
//

import Foundation
import AVFoundation

class PlayerViewModel: ObservableObject {
    let player = AVPlayer()

    func playMedia(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }

    func stopMedia() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
