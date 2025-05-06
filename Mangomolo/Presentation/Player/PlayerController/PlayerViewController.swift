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
    var isContentFinished = false
    var shouldDismissAfterPostroll = false
    var playerLayer: AVPlayerLayer?
    var customControlsView: UIView!
    var playPauseButton: UIButton!
    var progressSlider: UISlider!
    var currentTimeLabel: UILabel!
    var durationLabel: UILabel!
    var hintStack: UIStackView!
    var adsLoader: IMAAdsLoader?
    var adsManager: IMAAdsManager?
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var player: AVPlayer?
    var adContainerView = UIView()
    var timeObserverToken: Any?
    var contentURL: URL
    var isSubscribed: Bool
    var lastPlaybackTime: CMTime = .zero
    var hasStartedContent = false
    var controlsTimer: Timer?
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    // Flag to track if we're in the process of dismissing
    var isDismissing = false
    
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
    
    @objc func handleDidBecomeActive() {
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
    func cleanupResources() {
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
        
        // Remove time observer
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        // Invalidate timer
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
    func setupPlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        if let layer = playerLayer {
            view.layer.addSublayer(layer)
        }
        
        // Setup custom controls
        setupCustomControls()
        view.bringSubviewToFront(customControlsView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tapGesture)
        
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
            self.hintStack.isHidden = size.width > size.height
        })
    }
    
    func playContent() {
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
    
    
    @objc func dismissAfterContentEnd() {
        dismissController()
    }
    
    // Centralized dismissal method (SwiftUI only)
    func dismissController() {
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
    
    func cleanupAfterDismiss() {
        let isLandscape = view.bounds.width > view.bounds.height
        if isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.cleanupResources()
            }
        } else {
            cleanupResources()
        }
    }
    
    
    // MARK: - Content Completion Handler
    @objc func playerDidFinishPlaying() {
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
