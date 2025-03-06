import SwiftUI
import Sharing

@MainActor
@Observable
class SideMenuViewModel: ViewModel {
  var navigationCoordinator: NavigationCoordinator
  var stationPlayer: StationPlayer
  var authService: AuthService
  var api: API
  var user: User? = nil

  var menuItems: [SideMenuRowType] {
      if let user = user, user.stations != nil {
        return SideMenuRowType.allCases
      }
      return SideMenuRowType.allCases.filter { $0 != .myStation }
    }

  init(navigationCoordinator: NavigationCoordinator = .shared,
       stationPlayer: StationPlayer = .shared,
       authService: AuthService = .shared,
       api: API = API()) {
    self.navigationCoordinator = navigationCoordinator
    self.stationPlayer = stationPlayer
    self.authService = authService
    self.api = api
    super.init()
    Task { await getUser() }
  }

  func getUser() async {
    guard let userId = authService.auth.jwtUser?.id else { return }
    do {
      self.user = try await self.api.getUser(userId: userId)
    } catch (let err) {
      print("Failed to fetch user \(err.localizedDescription)")
    }
  }

  var selectedSideMenuTab: SideMenuRowType {
      get {
        switch navigationCoordinator.activePath {
        case .about:
          return .about
        case .listen:
          return .listen
        case .signIn:
          return .listen
        case .myStation:
          return .about
        }
      }
      set {
        switch newValue {
        case .about:
          self.navigationCoordinator.activePath = .about
        case .listen:
          self.navigationCoordinator.activePath = .listen
        case .myStation:
          // TODO: Add navigation to my station screen
          break
        }
      }
    }

  func rowTapped(row: SideMenuRowType) {
    self.selectedSideMenuTab = row
    self.navigationCoordinator.slideOutMenuIsShowing = false
  }

  func signOutTapped() {
    navigationCoordinator.activePath = .signIn
    stationPlayer.stop()
    authService.signOut()
    navigationCoordinator.slideOutMenuIsShowing = false
  }
}

enum SideMenuRowType: Int, CaseIterable, Equatable {
  case listen = 0
  case about
  case myStation

  var title: String{
    switch self {
    case .listen:
      return "Listen"
    case .about:
      return "About"
    case .myStation:
      return "My Station"
    }
  }

  var iconName: String{
    switch self {
    case .listen:
      return "headphones"
    case .about:
      return "info.circle"
    case .myStation:
      return "antenna.radiowaves.left.and.right"
    }
  }
}

@MainActor
struct SideMenuView: View {
  var model: SideMenuViewModel
  var body: some View {
    HStack {
      ZStack {

        VStack(alignment: .leading, spacing: 0) {
          ForEach(SideMenuRowType.allCases, id: \.self) { row in
            RowView(isSelected: model.selectedSideMenuTab == row,
                    imageName: row.iconName,
                    title: row.title) {
              model.rowTapped(row: row)
            }
          }
          Spacer()

          RowView(isSelected: false, imageName: "rectangle.portrait.and.arrow.right", title: "Sign Out") {
            model.signOutTapped()
          }
          .padding(.bottom, 30) // Adjust bottom padding as needed
        }
        .padding(.top, 100)
      }
      Spacer()
    }
    .background(.black)
  }

  func RowView(isSelected: Bool, imageName: String, title: String, hideDivider: Bool = false, action: @escaping (()->())) -> some View {
    Button {
      action()
    } label: {
      VStack(alignment: .leading) {
        HStack(spacing: 20) {
          Rectangle()
            .fill(isSelected ? Color.gray : .clear)
            .frame(width: 5)
          ZStack {
            Image(systemName: imageName)
              .resizable()
              .renderingMode(.template)
              .foregroundColor(isSelected ? .white : .gray)
              .frame(width: 26, height: 26)
          }
          .frame(width: 30, height: 30)
          Text(title)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(isSelected ? .white : .gray)
          Spacer()
        }
      }
    }
    .frame(height: 50)
    .background(
      LinearGradient(colors: [isSelected ? .white.opacity(0.5) : .clear, .clear],
                     startPoint: .leading,
                     endPoint: .trailing)
    )
  }
}
