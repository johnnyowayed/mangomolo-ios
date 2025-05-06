//
//  PlayerViewController+Observers.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 07/05/2025.
//

import AVFoundation

extension PlayerViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            if let statusNumber = change?[.newKey] as? Int,
               let status = AVPlayer.TimeControlStatus(rawValue: statusNumber) {
                DispatchQueue.main.async {
                    switch status {
                    case .waitingToPlayAtSpecifiedRate:
                        self.loadingIndicator.startAnimating()
                    case .playing, .paused:
                        self.loadingIndicator.stopAnimating()
                    @unknown default:
                        self.loadingIndicator.stopAnimating()
                    }
                }
            }
        }
    }

    func setupTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = player.currentItem?.duration else { return }
            let totalSeconds = CMTimeGetSeconds(duration)
            let currentSeconds = CMTimeGetSeconds(time)

            if totalSeconds.isFinite && currentSeconds.isFinite {
                self.progressSlider.value = Float(currentSeconds / totalSeconds)
                self.currentTimeLabel.text = self.formatTime(currentSeconds)
                self.durationLabel.text = self.formatTime(totalSeconds)
            }
        }
    }

    func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
