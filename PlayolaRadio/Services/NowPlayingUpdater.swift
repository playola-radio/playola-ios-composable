//
//  NowPlayingUpdater.swift
//  PlayolaRadio
//
//  Created by Brian D Keane on 1/20/25.
//
import Combine
import MediaPlayer

@MainActor
class NowPlayingUpdater {
    var stationPlayer: StationPlayer

    static var shared = NowPlayingUpdater()

    private var disposeBag = Set<AnyCancellable>()
    private func updateNowPlaying(with stationPlayerState: StationPlayer.State) {
        var nowPlayingInfo = [String: Any]()

        guard let currentStation = stationPlayer.currentStation else {
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            return
        }
        MPNowPlayingInfoCenter.default().playbackState = .playing

        if let artistPlaying = stationPlayerState.artistPlaying {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistPlaying
        }

        if let titlePlaying = stationPlayerState.titlePlaying {
            nowPlayingInfo[MPMediaItemPropertyTitle] = titlePlaying
        }

        if let imageUrl = stationPlayerState.albumArtworkUrl ?? URL(string: currentStation.imageURL) {
            UIImage.image(from: imageUrl) { image in
                if let image {
                    Task { await self.updateNowPlayingImage(image) }
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingImage(_ image: UIImage) {
        var nowPlayingInfo: [String: Any] = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in
            image
        })
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    init(stationPlayer: StationPlayer? = nil) {
        self.stationPlayer = stationPlayer ?? .shared
        self.stationPlayer.$state.sink { state in
            self.updateNowPlaying(with: state)
        }.store(in: &disposeBag)
        setupRemoteControlCenter()
    }

    func setupRemoteControlCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { _ in
            self.stationPlayer.stop()
            return .success
        }
    }
}
