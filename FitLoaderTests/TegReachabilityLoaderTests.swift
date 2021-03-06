import UIKit
import XCTest
import Dodo
import MprHttp

class TegReachabilityLoaderTests: XCTestCase {
  
  var httpTextMock: TegHttpTextMock!
  var viewControllerMock: ReachableViewControllerMock!
  var dodoMock: DodoMock!
  var reachabilityMock: ReachabilityMock!
  var identity: TegHttpRequestIdentity!
  
  override func setUp() {
    super.setUp()
    
    identity = TegHttpRequestIdentity(url: "http://test.com")
    
    // Mock view controller
    httpTextMock = TegHttpTextMock()
    viewControllerMock = ReachableViewControllerMock()
    
    // Mock Dodo
    dodoMock = DodoMock()
    viewControllerMock.view.dodo = dodoMock
    
    // Mock reachability
    reachabilityMock = ReachabilityMock()
    TegReachability.shared.reachability = reachabilityMock
  }
  
  // MARK: - Handle success
  
  func testGetSuccessfulTextResponse() {
    var actualBodyText = ""
    
    let loader = TegReachabilityLoader(httpText: httpTextMock,
      requestIdentity: identity,
      viewController: viewControllerMock,
      authentication: nil,
      onSuccess: { text in
        actualBodyText = text
        return true
      }
    )
    
    loader.startLoading()
    httpTextMock.simulateSuccessfulResponse(bodyText: "🐳")
    
    XCTAssertEqual("🐳", actualBodyText)
    XCTAssert(viewControllerMock.failedLoader === nil)
  }
  
  func testShowKnownError422() {
    let loader = TegReachabilityLoader(httpText: httpTextMock,
      requestIdentity: identity,
      viewController: viewControllerMock,
      authentication: nil,
      onSuccess: { text in
        return true
      }
    )
    
    loader.startLoading()
    httpTextMock.simulateError_unprocessableEntity422("{ \"knownErrorText\": \"📵\" }")
    
    XCTAssert(dodoMock.results.visible)
    XCTAssertEqual(1, dodoMock.results.total)
    XCTAssertEqual("📵", dodoMock.results.errors[0])
    XCTAssert(viewControllerMock.failedLoader === loader)
  }
  
  func testShowUnknownNetworkError() {
    let loader = TegReachabilityLoader(httpText: httpTextMock,
      requestIdentity: identity,
      viewController: viewControllerMock,
      authentication: nil,
      onSuccess: { text in true }
    )
    
    loader.startLoading()
    httpTextMock.simulateError(500, bodyTest: "Server error")
    
    XCTAssert(dodoMock.results.visible)
    XCTAssertEqual(1, dodoMock.results.total)
    XCTAssertEqual("Connection error", dodoMock.results.errors[0])
    XCTAssert(viewControllerMock.failedLoader === loader)
  }
  
  func testShowUnexpectedResponseError() {
    let loader = TegReachabilityLoader(httpText: httpTextMock,
      requestIdentity: identity,
      viewController: viewControllerMock,
      authentication: nil,
      onSuccess: { text in false } // return false - which is unexpected response
    )
    
    loader.startLoading()
    httpTextMock.simulateSuccessfulResponse(bodyText: "🐞")
    
    XCTAssert(dodoMock.results.visible)
    XCTAssertEqual(1, dodoMock.results.total)
    XCTAssertEqual("Unexpected response", dodoMock.results.errors[0])
    XCTAssert(viewControllerMock.failedLoader === loader)
  }
  
  func testShowNoInternetError() {
    let loader = TegReachabilityLoader(httpText: httpTextMock,
      requestIdentity: identity,
      viewController: viewControllerMock,
      authentication: nil,
      onSuccess: { text in true }
    )
    
    loader.startLoading()
    reachabilityMock.currentReachabilityStatusMock = NetworkStatus(NotReachable.rawValue)
    httpTextMock.simulateError(500, bodyTest: "Server error")
    
    XCTAssert(dodoMock.results.visible)
    XCTAssertEqual(1, dodoMock.results.total)
    XCTAssertEqual("No Internet connection", dodoMock.results.errors[0])
    XCTAssert(viewControllerMock.failedLoader === loader)
  }
}