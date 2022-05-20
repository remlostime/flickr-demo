import Foundation
import ComposableArchitecture
@testable import Flickr

enum FlickrResponse {
  case success(SearchResult)
  case failed(APIError)
  case empty
}

class MockFlickrNetworkClient: FlickrNetworkClient {
  private let response: FlickrResponse

  init(response: FlickrResponse) {
    self.response = response
  }

  func fetchData(for url: URL) -> Effect<SearchResult, APIError> {
    switch response {
      case .success(let result):
        return Effect(value: result)
      case .failed(let error):
        return Effect(error: error)
      case .empty:
        return Effect(value: SearchResult(photos: Photos(page: 0, pages: 0, perpage: 0, photo: [])))
    }
  }
}

