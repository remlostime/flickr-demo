import SwiftUI
import ComposableArchitecture
import Combine
import Kingfisher

struct MyAsyncImage: View {

  @State private var image: UIImage? = nil
  var url: URL
  @State private var subscriptions: Set<AnyCancellable> = []

  var body: some View {
    if let image = image {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
    } else {
      ProgressView()
        .onAppear {
          // 1) NSData
//          DispatchQueue.global().async {
//            if let nsdata = NSData(contentsOf: url) {
//              let data = Data(referencing: nsdata)
//              DispatchQueue.main.async {
//                self.image = UIImage(data: data)
//              }
//            }
//          }

          // 2) URLSession
//          URLSession.shared.dataTask(with: url) { data, _, _ in
//            if let data = data {
//              DispatchQueue.main.async {
//                self.image = UIImage(data: data)
//              }
//            }
//          }.resume()

          // 3) Combine
//          URLSession.shared.dataTaskPublisher(for: url)
//            .map(\.data)
//            .receive(on: DispatchQueue.main)
//            .sink { _ in
//            } receiveValue: { data in
//              image = UIImage(data: data)
//            }
//            .store(in: &subscriptions)

          URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .assign(to: \.image, on: self)
            .store(in: &subscriptions)
        }
    }
  }
}

struct ContentView: View {
  let store: Store<MainState, MainAction>
  @State var text: String = ""

  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationView {
        ScrollView {
          LazyVGrid(
            columns: [
              GridItem(.adaptive(minimum: 100, maximum: 250))
            ],
            spacing: 16
          ) {
            ForEach(viewStore.photos.photo, id: \.id) { photo in
              NavigationLink {
                AsyncImage(url: photo.url(for: "m")) { image in
                  image
                    .resizable()
                    .scaledToFit()
                } placeholder: {
                  ProgressView()
                }
                .frame(width: 400, height: 400)
              } label: {
//                AsyncImage(url: photo.url(for: "s")) { phase in
//                  switch phase {
//                    case .empty:
//                      ProgressView()
//                    case .success(let image):
//                      image
//                        .resizable()
//                        .scaledToFit()
//                    case .failure:
//                      Image(systemName: "photo")
//                        .onAppear {
//                          print("bad image: \(photo.url(for: "s"))")
//                        }
//                    @unknown default:
//                      EmptyView()
//                  }
//                }
                KFImage(photo.url(for: "s"))
                  .resizable()
                  .scaledToFit()
                .onAppear {
                  viewStore.send(.loadMore(currentPhoto: photo))
                }
              }
            }
          }
        }
        .searchable(text: viewStore.binding(get: { $0.keyword }, send: { .searchPhoto(text: $0) }))
        .navigationTitle("Flickr")
      }
      .navigationViewStyle(StackNavigationViewStyle())
      .onAppear {
        viewStore.send(.searchPhoto(text: "cat"))
      }
      .alert(isPresented: viewStore.binding(get: { $0.errorIsPresented }, send: { .errorAlertDidToggle(value: $0) })) {
        Alert(title: Text("Error"), message: Text(viewStore.error?.description ?? "Something goes wrong!"))
      }
      .overlay {
        if viewStore.isLoading {
          ZStack {
            ProgressView()
            Color.black
              .opacity(0.5)
              .frame(width: 50, height: 50)
              .cornerRadius(8.0)
          }
        } else {
          EmptyView()
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(store: Store(initialState: MainState(), reducer: MainReducerBuilder.build(), environment: MainEnvironment(networkClient: DefaultFlickrNetworkClient(), scheduler: DispatchQueue.main.eraseToAnyScheduler())))
  }
}
