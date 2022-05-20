import Foundation
import ComposableArchitecture

enum APIError: Error, CustomStringConvertible {
  case decoding
  case download

  var description: String {
    let description: String
    switch self {
      case .decoding:
        description = "Something wrong with Decoding"
      case .download:
        description = "Download failed"
    }

    return localizedDescription + "\n" + description
  }
}

protocol FlickrNetworkClient {
  func fetchData(for url: URL) -> Effect<SearchResult, APIError>
}

class DefaultFlickrNetworkClient: FlickrNetworkClient {
  private lazy var decoder: JSONDecoder = {
    let decoder = JSONDecoder()

    return decoder
  }()

  func fetchData(for url: URL) -> Effect<SearchResult, APIError> {
    return URLSession.shared.dataTaskPublisher(for: url)
      .mapError { _ in APIError.download }
      .map(\.data)
      .decode(type: SearchResult.self, decoder: decoder)
      .mapError { _ in APIError.decoding }
      .eraseToEffect()
  }
}

