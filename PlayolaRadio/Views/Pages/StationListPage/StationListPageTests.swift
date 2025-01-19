//
//  Untitled.swift
//  PlayolaRadio
//
//  Created by Brian D Keane on 1/16/25.
//
import Testing
import FRadioPlayer
import Sharing
@testable import PlayolaRadio

struct StationListPageTests {

  @MainActor @Suite("ViewAppeared")
  struct ViewAppeared {
    
    @Test("Retrieves the list -- working")
    func testCorrectlyRetrievesStationListsWhenApiIsSuccessful() async {
      @Shared(.stationListsLoaded) var stationListsLoaded = false
      @Shared(.stationLists) var stationLists = StationList.mocks
      let apiMock = APIMock(getStationListsShouldSucceed: true)
      let stationListModel = StationListModel(api: apiMock)
      apiMock.beforeAssertions = {
        #expect(stationListModel.isLoadingStationLists == true)
      }
      await stationListModel.viewAppeared()
      #expect(stationListModel.stationLists.elementsEqual(StationList.mocks))
      #expect(stationListModel.isLoadingStationLists == false)
    }

    @Test("Displays an error alert on api error")
    func testDisplaysAnErrorAlertOnApiError() async {
      let apiMock = APIMock(getStationListsShouldSucceed: false)
      let stationListModel = StationListModel(api: apiMock)
      apiMock.beforeAssertions = {
        #expect(stationListModel.isLoadingStationLists == true)
      }
      await stationListModel.viewAppeared()
      #expect(stationListModel.presentedAlert == .errorLoadingStations)
      #expect(stationListModel.isLoadingStationLists == false)
    }

    @Test("Subscribes to stationPlayer changes")
    func testSubscribesToStationPlayerChanges() async {
      let stationPlayerMock = StationPlayerMock()
      let apiMock = APIMock()
      let stationListModel = StationListModel(api: apiMock, stationPlayer: stationPlayerMock)
      #expect(stationListModel.stationPlayerState.playbackStatus ~=  .stopped)

      let newState = StationPlayer.State(playbackStatus: .playing(.mock), artistPlaying: "Rachel Loy", titlePlaying: "Selfie")
      stationPlayerMock.state = newState

      // TODO: Figure out how to wait for this value to change
//      #expect(stationListModel.stationPlayerState == newState)
    }
  }
  
  @MainActor @Suite("NowPlaying little view")
  struct NowPlayingLittleView {
    @Test("Navigates to now playing when NowPlaying is tapped")
    func testNavigatesToNowPlayingWhenNowPlayingIsTapped() async {
      let stationPlayerMock: StationPlayerMock = .mockPlayingPlayer()
      let navigationCoordinator = NavigationCoordinator()
      let stationListPage = StationListModel(stationPlayer: stationPlayerMock,
                                             navigationCoordinator: navigationCoordinator)
      await stationListPage.viewAppeared()
      stationListPage.nowPlayingToolbarButtonTapped()
      #expect(navigationCoordinator.path.last ~= .nowPlayingPage(NowPlayingPageModel()))
    }

    @Test("Navigates nowhere if it is tapped while a station is not playing")
    func testNavigatesNowhereIfTappedWhileAStationIsNotPlaying() async {
      let stationPlayerMock: StationPlayerMock = .mockStoppedPlayer()

      let navigationCoordinator = NavigationCoordinatorMock()
      let stationListPage = StationListModel(stationPlayer: stationPlayerMock,
                                             navigationCoordinator: navigationCoordinator)
      await stationListPage.viewAppeared()
      stationListPage.nowPlayingToolbarButtonTapped()
      #expect(navigationCoordinator.changesToPathCount == 0)
    }

    @Test("Selecting a station starts it and moves to nowPlaying")
    func testSelectingAStationStartsItAndMovesToNowPlaying() async {
      let stationPlayerMock: StationPlayerMock = .mockStoppedPlayer()
      let station: RadioStation = .mock

      let navigationCoordinator = NavigationCoordinatorMock()
      let stationListPage = StationListModel(stationPlayer: stationPlayerMock,
                                             navigationCoordinator: navigationCoordinator)
      await stationListPage.viewAppeared()
      stationListPage.stationSelected(station)
      #expect(navigationCoordinator.changesToPathCount == 1)
      #expect(navigationCoordinator.path.last ~= .nowPlayingPage(NowPlayingPageModel()))
      #expect(stationPlayerMock.callsToPlay.count == 1)
    }
  }

}
