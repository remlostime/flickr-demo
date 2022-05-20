import SwiftUI
import ComposableArchitecture

@main
struct FlickrApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        store: Store(
          initialState: MainState(),
          reducer: MainReducerBuilder.build(),
          environment: MainEnvironment(networkClient: DefaultFlickrNetworkClient(), scheduler: DispatchQueue.main.eraseToAnyScheduler())
        )
      )
    }
  }
}
