import Foundation

struct SearchResult: Decodable, Equatable {
  var photos: Photos
}

struct Photos: Decodable, Equatable {
  let page: Int
  let pages: Int
  let perpage: Int
  var photo: [Photo]
}

struct Photo: Decodable, Equatable, Identifiable {
  let secret: String
  let farm: Int
  let title: String
  let id: String
  let server: String
}

extension Photo {
  func url(for size: String) -> URL {
    URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(size).jpg")!
  }
}
