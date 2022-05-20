import Foundation
import ComposableArchitecture

enum MainAction: Equatable {
  case searchPhoto(text: String)
  case dataDidLoad(result: Result<SearchResult, APIError>)
  case errorAlertDidToggle(value: Bool)
  case loadMore(currentPhoto: Photo)
}

struct MainState: Equatable {
  var photos: Photos = Photos(page: 0, pages: 0, perpage: 20, photo: [])
  var error: APIError? = nil
  var errorIsPresented: Bool = false
  var keyword: String = ""
  var apiKey: String = "4b8d72e369b0ea35b972009d303e1023"
  var isLoading: Bool = false

  var url: URL {
    let queryKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    return URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(queryKeyword)&per_page=\(photos.perpage)&page=\(photos.page+1)&format=json&nojsoncallback=1")!
  }
}

struct MainEnvironment {
  var networkClient: FlickrNetworkClient
  var scheduler: AnySchedulerOf<DispatchQueue>
}

typealias MainReducer = Reducer<MainState, MainAction, MainEnvironment>

struct MainReducerBuilder {
  static func build() -> MainReducer {
    MainReducer { state, action, environment in
      switch action {
        case .loadMore(let photo):
          guard !state.isLoading else {
            return .none
          }

          let threshold = 2
          guard
            let index = state.photos.photo.firstIndex(of: photo),
            index + threshold >= state.photos.photo.count else
          {
            return .none
          }

          state.isLoading = true

          return environment.networkClient.fetchData(for: state.url)
            .receive(on: environment.scheduler)
            .catchToEffect()
            .map(MainAction.dataDidLoad)
        case .searchPhoto(let text):
          state.keyword = text
          state.photos = Photos(page: 0, pages: 0, perpage: 20, photo: [])

          guard !text.isEmpty else {
            return .none
          }

          state.isLoading = true

          struct CancelDelayId: Hashable {}

          return environment.networkClient.fetchData(for: state.url)
            .receive(on: environment.scheduler)
            .catchToEffect()
            .throttle(id: CancelDelayId(), for: 0.5, scheduler: environment.scheduler, latest: false)
//            .debounce(id: CancelDelayId(), for: 0.5, scheduler: environment.scheduler)
            .map(MainAction.dataDidLoad)
        case .dataDidLoad(let result):
          state.isLoading = false
          switch result {
            case .success(let searchResult):
              // exist photos
              var photos = state.photos.photo
              // exist photos + new photos
              photos.append(contentsOf: searchResult.photos.photo)
              // save metadata into state
              state.photos = searchResult.photos
              // update photos with all photos(exist + new)
              state.photos.photo = photos
            case .failure(let error):
              state.error = error
              state.errorIsPresented = true
          }
          return .none
        case .errorAlertDidToggle(let value):
          state.errorIsPresented = value
          return .none
      }
    }
  }
}
