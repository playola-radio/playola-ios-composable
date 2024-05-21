//
//  StationListPageTests.swift
//  PlayolaRadioTests
//
//  Created by Brian D Keane on 5/21/24.
//

import ComposableArchitecture
import XCTest

@testable import PlayolaRadio

final class StationListPageTests: XCTestCase {
  @MainActor
  func testGetStationsSuccess() async {
    let store = TestStore(initialState: StationListReducer.State()) {
      StationListReducer()
    } withDependencies: {
      $0.apiClient.getStationLists = { StationList.mocks }
    }

    let monitorStationStoreTask = await store.send(.viewAppeared) {
      $0.isLoadingStationLists = true
    }

    await store.receive(\.stationsListResponseReceived.success) {
      $0.isLoadingStationLists = false
      $0.stationLists = IdentifiedArray(uniqueElements: StationList.mocks.filter { $0.id != "in_development" })
    }

    await monitorStationStoreTask.cancel()
  }

  @MainActor
  func testReceivedStationListsWhenShowingInDevelopement() async {
    let store = TestStore(initialState: StationListReducer.State(isShowingSecretStations: true)) {
      StationListReducer()
    } withDependencies: {
      $0.apiClient.getStationLists = { StationList.mocks }
    }

    await store.send(.stationsListResponseReceived(.success(StationList.mocks))) {
      $0.stationLists = IdentifiedArray(uniqueElements: StationList.mocks)
    }
  }

  @MainActor
  func testGetStationFailure() async {
    let store = TestStore(initialState: StationListReducer.State(isShowingSecretStations: true)) {
      StationListReducer()
    } withDependencies: {
      $0.apiClient.getStationLists = {
        struct SomethingWentWrong: Error {}
        throw SomethingWentWrong()
      }
    }

    let monitorStationStoreTask = await store.send(.viewAppeared) {
      $0.isLoadingStationLists = true
    }

    await store.receive(\.stationsListResponseReceived.failure) {
      $0.isLoadingStationLists = false
    }

    await monitorStationStoreTask.cancel()
  }
}