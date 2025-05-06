//
//  PlayerViewController.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 05/05/2025.
//

import Foundation
import AVKit
import SwiftUI
import GoogleInteractiveMediaAds

class PlayerViewController: UIViewController {
    // Closure to handle dismissal (for SwiftUI)
    var onDismiss: (() -> Void)?
    // Tracks if the content has finished to inform IMA SDK for post-roll
    private var isContentFinished = false
    private var shouldDismissAfterPostroll = false
    private var playerLayer: AVPlayerLayer?
    private let customControlsView = UIView()
    private let playPauseButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private var adsLoader: IMAAdsLoader?
    private var adsManager: IMAAdsManager?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var player: AVPlayer?
    private var adContainerView = UIView()
    private var timeObserverToken: Any?
    private var contentURL: URL
    private var isSubscribed: Bool
    private var lastPlaybackTime: CMTime = .zero
    private var hasStartedContent = false
    private var controlsTimer: Timer?
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    // Flag to track if we're in the process of dismissing
    private var isDismissing = false

    init(contentURL: URL, isSubscribed: Bool) {
        self.contentURL = contentURL
        self.isSubscribed = isSubscribed
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        // Remove observer for buffering state
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        setupPlayer()
    }

    @objc private func handleDidBecomeActive() {
        adsManager?.resume()
    }
       
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only clean up resources if the view is being dismissed or popped, not just rotated
        if isMovingFromParent || isBeingDismissed {
            cleanupResources()
        }
    }
    
    // Clean up method to ensure proper resource release
    private func cleanupResources() {
        // Remove observers
        if let currentItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        NotificationCenter.default.removeObserver(self)
        
        // Stop player and clear item
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        // Clean up ad manager
        adsManager?.pause()
//        adsLoader?.contentComplete()
        
        // Remove time observer
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        // Invalidate timer
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
    private func setupPlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        if let layer = playerLayer {
            view.layer.addSublayer(layer)
        }

        // Setup custom controls
        setupCustomControls()

        // Ad container
        adContainerView.frame = view.bounds
        adContainerView.backgroundColor = .clear
        adContainerView.isUserInteractionEnabled = !isSubscribed
        view.addSubview(adContainerView)
        


        // Setup loading indicator
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()

        // Add observer for buffering state
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .initial], context: nil)

        if isSubscribed {
            playContent()
        } else {
            requestAds()
        }
    }
    // Observe player buffering and show/hide loading indicator accordingly
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
    
    private func setupCustomControls() {
        customControlsView.frame = view.bounds
        customControlsView.backgroundColor = .clear
        view.addSubview(customControlsView)

        // --- Orientation hint: icon + label in vertical stack ---
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

        let hintStack = UIStackView(arrangedSubviews: [icon, label])
        hintStack.axis = .vertical
        hintStack.spacing = 8
        hintStack.alignment = .center
        hintStack.translatesAutoresizingMaskIntoConstraints = false
        hintStack.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        hintStack.layer.cornerRadius = 10
        hintStack.clipsToBounds = true
        hintStack.tag = 999

        customControlsView.addSubview(hintStack)

        NSLayoutConstraint.activate([
            hintStack.topAnchor.constraint(equalTo: customControlsView.safeAreaLayoutGuide.topAnchor, constant: 80),
            hintStack.centerXAnchor.constraint(equalTo: customControlsView.centerXAnchor),
            hintStack.widthAnchor.constraint(lessThanOrEqualTo: customControlsView.widthAnchor, multiplier: 0.9),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Play/Pause
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseButton.contentHorizontalAlignment = .fill
        playPauseButton.contentVerticalAlignment = .fill
        playPauseButton.imageView?.contentMode = .scaleAspectFit
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        customControlsView.addSubview(playPauseButton)

        // --- Add 15s rewind and forward buttons ---
        let rewindButton = UIButton(type: .system)
        rewindButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        rewindButton.tintColor = .white
        rewindButton.translatesAutoresizingMaskIntoConstraints = false
        rewindButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        rewindButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        rewindButton.addTarget(self, action: #selector(rewind15Seconds), for: .touchUpInside)
        customControlsView.addSubview(rewindButton)

        let forwardButton = UIButton(type: .system)
        forwardButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forwardButton.tintColor = .white
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        forwardButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        forwardButton.addTarget(self, action: #selector(forward15Seconds), for: .touchUpInside)
        customControlsView.addSubview(forwardButton)

        NSLayoutConstraint.activate([
            rewindButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor),
            rewindButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -30),

            playPauseButton.centerXAnchor.constraint(equalTo: customControlsView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor),

            forwardButton.centerYAnchor.constraint(equalTo: customControlsView.centerYAnchor),
            forwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 30)
        ])

        // Add close button to top-left
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissAfterContentEnd), for: .touchUpInside)
        customControlsView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: customControlsView.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: customControlsView.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Slider and labels inline in stack view
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.setThumbImage(UIImage(systemName: "circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 8)), for: .normal)
        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.maximumTrackTintColor = .lightGray

        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .white
        durationLabel.text = "0:00"
        durationLabel.textColor = .white

        // Remove old adds and constraints for currentTimeLabel/durationLabel/progressSlider
        // Instead, use stack view
        let sliderContainer = UIStackView(arrangedSubviews: [currentTimeLabel, progressSlider, durationLabel])
        sliderContainer.axis = .horizontal
        sliderContainer.spacing = 8
        sliderContainer.alignment = .center
        sliderContainer.translatesAutoresizingMaskIntoConstraints = false
        customControlsView.addSubview(sliderContainer)

        NSLayoutConstraint.activate([
            sliderContainer.leadingAnchor.constraint(equalTo: customControlsView.leadingAnchor, constant: 16),
            sliderContainer.trailingAnchor.constraint(equalTo: customControlsView.trailingAnchor, constant: -16),
            sliderContainer.bottomAnchor.constraint(equalTo: customControlsView.bottomAnchor, constant: -40),
            progressSlider.heightAnchor.constraint(equalToConstant: 30)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tap)
        startControlsTimer()
    }
    
    @objc private func toggleControls() {
        let shouldShow = customControlsView.alpha == 0
        UIView.animate(withDuration: 0.25) {
            self.customControlsView.alpha = shouldShow ? 1 : 0
        }
        if shouldShow { startControlsTimer() }
    }

    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            UIView.animate(withDuration: 0.25) {
                self?.customControlsView.alpha = 0
            }
        }
    }
    
    @objc private func rewind15Seconds() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 600))
        player?.seek(to: newTime)
    }

    @objc private func forward15Seconds() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 600))
        player?.seek(to: newTime)
    }
    
    @objc private func togglePlayPause() {
        if player?.timeControlStatus == .playing {
            player?.pause()
        } else {
            player?.play()
        }

        // Ensure icon is updated correctly after playback state stabilizes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updatePlayPauseIcon()
        }
    }

    private func updatePlayPauseIcon() {
        guard let player = player else { return }
        let isPlaying = player.rate != 0 && player.error == nil
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let duration = player?.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let value = Double(sender.value) * totalSeconds
        let seekTime = CMTime(seconds: value, preferredTimescale: 600)
        player?.seek(to: seekTime)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.playerLayer?.frame = CGRect(origin: .zero, size: size)
            self.adContainerView.frame = CGRect(origin: .zero, size: size)
            self.customControlsView.frame = CGRect(origin: .zero, size: size)
        }, completion: { _ in
            // Ensure layout is stable post-transition
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            if let hint = self.customControlsView.viewWithTag(999) {
                hint.isHidden = size.width > size.height // hide in landscape, show in portrait
            }
        })
    }
    
    private func playContent() {
        if !hasStartedContent {
            let item = AVPlayerItem(url: contentURL)
            player?.replaceCurrentItem(with: item)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )
            hasStartedContent = true
        }
        if lastPlaybackTime.isValid && lastPlaybackTime.isNumeric {
            player?.seek(to: lastPlaybackTime) { [weak self] _ in
                self?.player?.play()
                self?.loadingIndicator.stopAnimating()
                self?.updatePlayPauseIcon()
                self?.setupTimeObserver()
            }
        } else {
            player?.play()
            loadingIndicator.stopAnimating()
            updatePlayPauseIcon()
            setupTimeObserver()
        }
    }
    
    private func setupTimeObserver() {
        // Remove existing observer if present
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        // Create new observer
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.player?.currentItem?.duration ?? .zero)

            if duration.isFinite && duration > 0 {
                self.progressSlider.value = Float(currentTime / duration)
                self.currentTimeLabel.text = self.formatTime(currentTime)
                self.durationLabel.text = self.formatTime(duration)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    @objc private func dismissAfterContentEnd() {
        dismissController()
    }
    
    // Centralized dismissal method (SwiftUI only)
    private func dismissController() {
        if isDismissing { return }
        isDismissing = true

        // Attempt to rotate to portrait
        if let windowScene = view.window?.windowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                print("⚠️ Orientation change failed: \(error.localizedDescription)")
            }
        }

        // Always proceed with dismissal after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.onDismiss?()
            self?.cleanupAfterDismiss()
        }
    }
    
    private func cleanupAfterDismiss() {
        let isLandscape = view.bounds.width > view.bounds.height
        if isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.cleanupResources()
            }
        } else {
            cleanupResources()
        }
    }
    
    private func requestAds() {
        let settings = IMASettings()
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader?.delegate = self
        
        guard let player = player else { return }
        lastPlaybackTime = player.currentTime()
        player.pause()
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
        
        let adTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator="
        
        let displayContainer = IMAAdDisplayContainer(adContainer: adContainerView, viewController: self, companionSlots: nil)
        
        let request = IMAAdsRequest(
            adTagUrl: adTagUrl,
            adDisplayContainer: displayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil
        )
        
        DispatchQueue.main.async {
            self.adsLoader?.requestAds(with: request)
        }
    }
    
    // MARK: - Content Completion Handler
    @objc private func playerDidFinishPlaying() {
        print("🎬 Content finished naturally — post-roll should trigger")
        isContentFinished = true
        shouldDismissAfterPostroll = true
        
        if isSubscribed {
            // If subscribed, dismiss after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.dismissController()
            }
        } else {
            // If not subscribed, notify the ads loader that content is complete
            // This should trigger the post-roll ad
            adsLoader?.contentComplete()
        }
    }
}

extension PlayerViewController: IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        adsManager?.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        playContent()
    }
    
    func adsManager(_ manager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == .LOADED {
            adsManager?.start()
        }
        
        if event.type == .ALL_ADS_COMPLETED && shouldDismissAfterPostroll {
            // Dismiss after all ads complete and content is finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.dismissController()
            }
        }
    }
    
    func adsManager(_ manager: IMAAdsManager, didReceive error: IMAAdError) {
        playContent()
    }
    
    func adsManagerDidRequestContentPause(_ manager: IMAAdsManager) {
        lastPlaybackTime = player?.currentTime() ?? .zero
        player?.pause()
        adContainerView.isUserInteractionEnabled = true
    }
    
    func adsManagerDidRequestContentResume(_ manager: IMAAdsManager) {
        adContainerView.isUserInteractionEnabled = false
        if !hasStartedContent {
            playContent()
        } else {
            if lastPlaybackTime.isValid && lastPlaybackTime.isNumeric {
                player?.seek(to: lastPlaybackTime) { [weak self] _ in
                    self?.player?.play()
                    self?.loadingIndicator.stopAnimating()
                    self?.updatePlayPauseIcon()
                }
            } else {
                player?.play()
                loadingIndicator.stopAnimating()
                updatePlayPauseIcon()
            }
        }
    }
}

// MARK: - SwiftUI Bridge

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

   
