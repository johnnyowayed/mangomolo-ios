//
//  PlayerViewController+Controls.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 07/05/2025.
//

import UIKit
import AVFoundation

extension PlayerViewController {

    func setupCustomControls() {
        // Create container view for custom controls
        customControlsView = UIView()
        customControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        customControlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customControlsView)

        let icon = UIImageView(image: UIImage(systemName: "iphone.landscape"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Rotate your phone for full-screen view"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2

        hintStack = UIStackView(arrangedSubviews: [icon, label])
        hintStack.axis = .vertical
        hintStack.spacing = 8
        hintStack.alignment = .center
        hintStack.translatesAutoresizingMaskIntoConstraints = false
        hintStack.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        hintStack.layer.cornerRadius = 10
        hintStack.clipsToBounds = true
        hintStack.tag = 999

        if view.bounds.height > view.bounds.width {
            view.addSubview(hintStack)
        }

        NSLayoutConstraint.activate([
            hintStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            hintStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintStack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Setup constraints for container view
        NSLayoutConstraint.activate([
            customControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customControlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customControlsView.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Create play/pause button
        playPauseButton = UIButton(type: .system)
        let playImage = UIImage(systemName: "play.fill")
        playPauseButton.setImage(playImage, for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        customControlsView.addSubview(playPauseButton)

        // Create rewind button
        let rewindButton = UIButton(type: .system)
        let rewindImage = UIImage(systemName: "gobackward.15")
        rewindButton.setImage(rewindImage, for: .normal)
        rewindButton.tintColor = .white
        rewindButton.translatesAutoresizingMaskIntoConstraints = false
        rewindButton.addTarget(self, action: #selector(rewind15Seconds), for: .touchUpInside)
        customControlsView.addSubview(rewindButton)

        // Create forward button
        let forwardButton = UIButton(type: .system)
        let forwardImage = UIImage(systemName: "goforward.15")
        forwardButton.setImage(forwardImage, for: .normal)
        forwardButton.tintColor = .white
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.addTarget(self, action: #selector(forward15Seconds), for: .touchUpInside)
        customControlsView.addSubview(forwardButton)

        // Create progress slider
        progressSlider = UISlider()
        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.maximumTrackTintColor = .lightGray
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        customControlsView.addSubview(progressSlider)

        // Create current time label
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        customControlsView.addSubview(currentTimeLabel)

        // Create duration label
        durationLabel = UILabel()
        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        customControlsView.addSubview(durationLabel)

        // Layout constraints for buttons and labels
        NSLayoutConstraint.activate([
            playPauseButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            playPauseButton.leadingAnchor.constraint(equalTo: customControlsView.leadingAnchor, constant: 16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 30),
            playPauseButton.heightAnchor.constraint(equalToConstant: 30),

            rewindButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            rewindButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 16),
            rewindButton.widthAnchor.constraint(equalToConstant: 30),
            rewindButton.heightAnchor.constraint(equalToConstant: 30),

            forwardButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            forwardButton.leadingAnchor.constraint(equalTo: rewindButton.trailingAnchor, constant: 16),
            forwardButton.widthAnchor.constraint(equalToConstant: 30),
            forwardButton.heightAnchor.constraint(equalToConstant: 30),

            currentTimeLabel.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            currentTimeLabel.leadingAnchor.constraint(equalTo: forwardButton.trailingAnchor, constant: 16),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 50),

            durationLabel.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            durationLabel.trailingAnchor.constraint(equalTo: customControlsView.trailingAnchor, constant: -16),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),

            progressSlider.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor, constant: -12),
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8)
        ])

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissAfterContentEnd), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Initially hide controls
        customControlsView.alpha = 0
        
    }

    @objc func toggleControls() {
        if controlsTimer != nil {
            controlsTimer?.invalidate()
            controlsTimer = nil
        }
        let shouldShow = customControlsView.alpha == 0
        UIView.animate(withDuration: 0.25) {
            self.customControlsView.alpha = shouldShow ? 1 : 0
        }
        if shouldShow {
            startControlsTimer()
        }
    }

    func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.25) {
                self.customControlsView.alpha = 0
            }
        }
    }

    @objc func rewind15Seconds() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        var newTime = CMTimeSubtract(currentTime, CMTimeMakeWithSeconds(15, preferredTimescale: currentTime.timescale))
        if CMTimeGetSeconds(newTime) < 0 {
            newTime = CMTimeMake(value: 0, timescale: currentTime.timescale)
        }
        player.seek(to: newTime)
    }

    @objc func forward15Seconds() {
        guard let player = player, let duration = player.currentItem?.duration else { return }
        let currentTime = player.currentTime()
        var newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(15, preferredTimescale: currentTime.timescale))
        if CMTimeGetSeconds(newTime) > CMTimeGetSeconds(duration) {
            newTime = duration
        }
        player.seek(to: newTime)
    }

    @objc func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        updatePlayPauseIcon()
        startControlsTimer()
    }

    func updatePlayPauseIcon() {
        guard let player = player else { return }
        let imageName = player.timeControlStatus == .playing ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName)
        playPauseButton.setImage(image, for: .normal)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        guard let player = player, let duration = player.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let value = Float64(sender.value) * totalSeconds
        let seekTime = CMTimeMakeWithSeconds(value, preferredTimescale: duration.timescale)
        player.seek(to: seekTime)
    }
}
