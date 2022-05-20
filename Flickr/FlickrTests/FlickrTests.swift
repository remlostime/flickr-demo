import XCTest
import ComposableArchitecture
@testable import Flickr

class FlickrTests: XCTestCase {
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testFetchData_Success() {
    let result = SearchResult(photos: Photos(page: 0, pages: 0, perpage: 0, photo: [
      Photo(secret: "aa", farm: 0, title: "aa", id: "aa", server: "aa"),
      Photo(secret: "bb", farm: 0, title: "bb", id: "bb", server: "bb")
    ]))

    let networkClient = MockFlickrNetworkClient(response: .success(result))

    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: MainState(),
      reducer: MainReducerBuilder.build(),
      environment: MainEnvironment(networkClient: networkClient, scheduler: scheduler.eraseToAnyScheduler()))

    store.send(.searchPhoto(text: "cat")) { state in
      state.isLoading = true
      state.keyword = "cat"
    }

    scheduler.advance(by: 1)

    store.receive(.dataDidLoad(result: .success(result))) { state in
      state.photos = result.photos
      state.isLoading = false
    }
  }

  func testFetchData_Fail() {
    let error = APIError.download
    let networkClient = MockFlickrNetworkClient(response: .failed(error))
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: MainState(),
      reducer: MainReducerBuilder.build(),
      environment: MainEnvironment(networkClient: networkClient, scheduler: scheduler.eraseToAnyScheduler()))

    store.send(.searchPhoto(text: "cat")) { state in
      state.keyword = "cat"
      state.isLoading = true
    }

    scheduler.advance(by: 1)

    store.receive(.dataDidLoad(result: .failure(error))) { state in
      state.isLoading = false
      state.error = error
      state.errorIsPresented = true
    }
  }

  func testFetchData_Empty() {
    let networkClient = MockFlickrNetworkClient(response: .empty)
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: MainState(),
      reducer: MainReducerBuilder.build(),
      environment: MainEnvironment(networkClient: networkClient, scheduler: scheduler.eraseToAnyScheduler()))

    store.send(.searchPhoto(text: "")) { state in
      state.isLoading = false
      state.keyword = ""
    }
  }

  func testFetchData_ErrorAlert() {
    let networkClient = MockFlickrNetworkClient(response: .empty)
    let scheduler = DispatchQueue.test
    let store = TestStore(
      initialState: MainState(),
      reducer: MainReducerBuilder.build(),
      environment: MainEnvironment(networkClient: networkClient, scheduler: scheduler.eraseToAnyScheduler()))

    let errorIsPresented = false
    store.send(.errorAlertDidToggle(value: errorIsPresented)) { state in
      state.errorIsPresented = errorIsPresented
    }
  }

}
