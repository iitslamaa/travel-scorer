//
//  VideoBackgroundView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/4/26.
//

import SwiftUI
import AVKit

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String
    let videoType: String
    let loop: Bool

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.load(videoName: videoName, videoType: videoType, loop: loop)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // Only update if the video identity actually changed
        uiView.updateIfNeeded(videoName: videoName, videoType: videoType, loop: loop)
    }
}

final class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    private var currentKey: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func load(videoName: String, videoType: String, loop: Bool) {
        let key = "\(videoName).\(videoType)-loop:\(loop)"
        currentKey = key

        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoType) else {
            assertionFailure("Missing bundled video: \(videoName).\(videoType)")
            return
        }

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        if loop {
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        }

        self.player = queuePlayer
        playerLayer.player = queuePlayer
        queuePlayer.play()
    }

    func updateIfNeeded(videoName: String, videoType: String, loop: Bool) {
        let newKey = "\(videoName).\(videoType)-loop:\(loop)"
        guard newKey != currentKey else { return }

        // Tear down and reload ONLY if identity changed
        player?.pause()
        looper = nil
        player = nil

        load(videoName: videoName, videoType: videoType, loop: loop)
    }
}
