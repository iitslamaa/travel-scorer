//
//  VideoBackgroundView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/4/26.
//

import Foundation
import SwiftUI
import AVKit

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String
    let videoType: String
    let loop: Bool

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(videoName: videoName, videoType: videoType, loop: loop)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.update(videoName: videoName, videoType: videoType, loop: loop)
    }
}

final class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var looper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?

    private var currentKey: String?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func configure(videoName: String, videoType: String, loop: Bool) {
        update(videoName: videoName, videoType: videoType, loop: loop)
    }

    func update(videoName: String, videoType: String, loop: Bool) {
        let newKey = "\(videoName).\(videoType)-loop:\(loop)"
        guard newKey != currentKey else { return }
        currentKey = newKey

        // Clean up
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        looper = nil
        queuePlayer = nil

        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoType) else {
            assertionFailure("Missing bundled video: \(videoName).\(videoType)")
            return
        }

        if loop {
            let asset = AVAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let qp = AVQueuePlayer(playerItem: item)
            qp.isMuted = true
            qp.actionAtItemEnd = .none

            // Loop forever
            looper = AVPlayerLooper(player: qp, templateItem: item)
            queuePlayer = qp
            player = qp
        } else {
            let p = AVPlayer(url: url)
            p.isMuted = true
            p.actionAtItemEnd = .pause
            player = p
        }

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        playerLayer = layer
        layer.frame = bounds

        player?.play()
    }
}
