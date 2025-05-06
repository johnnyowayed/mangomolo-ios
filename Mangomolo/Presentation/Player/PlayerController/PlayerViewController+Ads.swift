//
//  PlayerViewController+Ads.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 07/05/2025.
//

import GoogleInteractiveMediaAds
import AVKit

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

    func requestAds() {
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
}
