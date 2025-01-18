//
//  NowPlayingPage.swift
//  PlayolaRadio
//
//  Created by Brian D Keane on 1/17/25.
//

import SwiftUI
import Combine

@Observable
class NowPlayingPageModel: ViewModel {
  var disposeBag: Set<AnyCancellable> = Set()

  // MARK: State
  var albumArtUrl: URL?
  var nowPlayingArtist: String = ""
  var nowPlayingTitle: String = ""
  var navigationBarTitle: String = ""
  var presentedSheet: PlayolaSheet?

  init(stationPlayer: StationPlayer? = nil,
       navigationCoordinator: NavigationCoordinator? = nil,
       presentedSheet: PlayolaSheet? = nil) {
    self.stationPlayer = stationPlayer ?? StationPlayer.shared
    self.navigationCoordinator = navigationCoordinator ?? .shared
    self.presentedSheet = presentedSheet
  }

  // MARK: Dependencies
  @ObservationIgnored var stationPlayer: StationPlayer
  @ObservationIgnored var navigationCoordinator: NavigationCoordinator

  func viewAppeared() {
    processNewStationState(stationPlayer.state)

    stationPlayer.$state.sink { self.processNewStationState($0) }.store(in: &disposeBag)
  }

  func aboutButtonTapped() {
    self.presentedSheet = .about(AboutPageModel())
  }

  func infoButtonTapped() {}
  func shareButtonTapped() {}
  func dismissAboutSheetButtonTapped() {
    self.presentedSheet = nil
  }
  func stopButtonTapped() {
    navigationCoordinator.path.removeLast()
  }

  // MARK: Actions

  // MARK: Helpers
  func processNewStationState(_ state: StationPlayer.State) {
    switch state.playbackStatus {
    case .playing(let radioStation):
      self.navigationBarTitle = "\(radioStation.name) \(radioStation.desc)"
      self.nowPlayingTitle = state.titlePlaying ?? "-------"
      self.nowPlayingArtist = state.artistPlaying ?? "-------"
      self.albumArtUrl = state.albumArtworkUrl ?? URL(string: radioStation.imageURL)
    case .loading(let radioStation):
      self.navigationBarTitle = "\(radioStation.name) \(radioStation.desc)"
      self.nowPlayingTitle = "\(radioStation.name) \(radioStation.desc)"
      self.nowPlayingArtist = "Station Loading..."
      self.albumArtUrl = URL(string: radioStation.imageURL)
    case .stopped:
      self.navigationBarTitle = "Playola Radio"
      self.nowPlayingArtist = "Player Stopped"
      self.nowPlayingTitle = "Player Stopped"
      self.albumArtUrl = nil
    case .error:
      self.navigationBarTitle = "Playola Radio"
      self.nowPlayingTitle = ""
      self.nowPlayingArtist = "Error Playing Station"
      self.albumArtUrl = nil
    }
  }
}

struct NowPlayingView: View {
  @Bindable var model: NowPlayingPageModel

  //  @State private var sliderValue: Double = .zero

  @MainActor
  init(model: NowPlayingPageModel? = nil) {
    self.model = model ?? NowPlayingPageModel()
    UINavigationBar.appearance().barStyle = .black
    UINavigationBar.appearance().tintColor = .white
    UINavigationBar.appearance().prefersLargeTitles = false
  }

  var body: some View {
    ZStack {
      Color.black
        .edgesIgnoringSafeArea(.all)

      VStack {
        AsyncImage(url: self.model.albumArtUrl ??
                   Bundle.main.url(forResource: "AppIcon", withExtension: "PNG"), transaction: Transaction(animation: .bouncy()))
        { result in
          result.image?
            .resizable()
            .scaledToFill()
            .frame(width: 274, height: 274)
            .padding(.top, 35)
            .transition(.move(edge: .top))
        }
        .frame(width: 274, height: 274)


        HStack(spacing: 12) {
          //              Image("btn-previous")
          //                  .resizable()
          //                  .frame(width: 45, height: 45)
          //                  .onTapGesture {
          //                      print("Back")
          //                  }
          //              Image("btn-play")
          //                  .resizable()
          //                  .frame(width: 45, height: 45)
          //                  .onTapGesture {
          //                      print("Back")
          //                  }
          Image(model.stationPlayer.currentStation != nil ? "btn-stop" : "btn-play")
//          Image("btn-play")
            .resizable()
            .frame(width: 45, height: 45)
            .onTapGesture {
              model.stopButtonTapped()
            }
          //              Image("btn-next")
          //                  .resizable()
          //                  .frame(width: 45, height: 45)
          //                  .onTapGesture {
          //                      print("Back")
          //                  }
        }
        .padding(.top, 30)

        //        HStack {
        //          Image("vol-min")
        //            .frame(width: 18, height: 16)
        //
        //          Slider(value: $sliderValue)
        //
        //          Image("vol-max")
        //            .frame(width: 18, height: 16)
        //        }

        Text(model.nowPlayingTitle)
          .font(.title)

        Text(model.nowPlayingArtist)

        Spacer()

        HStack {

          AirPlayView()
            .frame(width: 42, height: 45)

          Spacer()

          Button(action: {}, label: {
            Image("share")
              .resizable()
              .foregroundColor(Color(hex: "#7F7F7F"))
              .frame(width: 26, height: 26)
          })

          Button(action: {}, label: {
            Image(systemName: "info.circle")
              .resizable()
              .foregroundColor(Color(hex: "#7F7F7F"))
              .frame(width: 22, height: 22)
          })
        }.padding(.leading, 35)
          .padding(.trailing, 35)
          .padding(.bottom, 75)
      }
    }
    .edgesIgnoringSafeArea(.bottom)
    .onAppear {
      model.viewAppeared()
    }
    .foregroundColor(.white)
    .accentColor(.white)
    .navigationTitle(model.navigationBarTitle)
    .navigationBarTitleDisplayMode(.inline)
  }

}

#Preview {
  NavigationStack {
    ZStack {
      Color.black
        .edgesIgnoringSafeArea(.all)

      NowPlayingView(model: NowPlayingPageModel(
        stationPlayer: .shared))
    }
  }
  .accentColor(.white)
}
