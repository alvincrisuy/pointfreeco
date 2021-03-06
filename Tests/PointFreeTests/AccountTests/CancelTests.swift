import Either
import Html
import HtmlPrettyPrint
import HttpPipeline
@testable import PointFree
import PointFreeTestSupport
import Prelude
import Optics
import SnapshotTesting
import XCTest
#if !os(Linux)
  import WebKit
#endif

final class CancelTests: TestCase {
  override func setUp() {
    super.setUp()
    AppEnvironment.push(\.database .~ .mock)
  }

  override func tearDown() {
    super.tearDown()
    AppEnvironment.pop()
  }

  func testCancel() {
    let conn = connection(from: request(to: .account(.subscription(.cancel)), session: .loggedIn))
    let result = conn |> siteMiddleware

    assertSnapshot(matching: result.perform())
  }

  func testCancelLoggedOut() {
    let conn = connection(from: request(to: .account(.subscription(.cancel))))
    let result = conn |> siteMiddleware

    assertSnapshot(matching: result.perform())
  }

  func testCancelNoSubscription() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(throwE(unit))) {
      let conn = connection(from: request(to: .account(.subscription(.cancel)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testCancelCancelingSubscription() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(pure(.canceling))) {
      let conn = connection(from: request(to: .account(.subscription(.cancel)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testCancelCanceledSubscription() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(pure(.canceled))) {
      let conn = connection(from: request(to: .account(.subscription(.cancel)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testCancelStripeFailure() {
    AppEnvironment.with(\.stripe.cancelSubscription .~ const(throwE(unit))) {
      let conn = connection(from: request(to: .account(.subscription(.cancel)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testCancelEmail() {
    let doc = cancelEmailView.view((.mock, .mock)).first!

    assertSnapshot(matching: render(doc, config: pretty), pathExtension: "html")
    assertSnapshot(matching: plainText(for: doc))

    #if !os(Linux)
      if #available(OSX 10.13, *) {
        let webView = WKWebView(frame: .init(x: 0, y: 0, width: 800, height: 800))
        webView.loadHTMLString(render(doc), baseURL: nil)
        assertSnapshot(matching: webView)

        webView.frame.size = .init(width: 400, height: 700)
        assertSnapshot(matching: webView)
      }
    #endif
  }

  func testReactivate() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(pure(.canceling))) {
      let conn = connection(from: request(to: .account(.subscription(.reactivate)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testReactivateLoggedOut() {
    let conn = connection(from: request(to: .account(.subscription(.reactivate))))
    let result = conn |> siteMiddleware

    assertSnapshot(matching: result.perform())
  }

  func testReactivateNoSubscription() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(throwE(unit))) {
      let conn = connection(from: request(to: .account(.subscription(.reactivate)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testReactivateActiveSubscription() {
    let conn = connection(from: request(to: .account(.subscription(.reactivate)), session: .loggedIn))
    let result = conn |> siteMiddleware

    assertSnapshot(matching: result.perform())
  }

  func testReactivateCanceledSubscription() {
    AppEnvironment.with(\.stripe.fetchSubscription .~ const(pure(.canceled))) {
      let conn = connection(from: request(to: .account(.subscription(.reactivate)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testReactivateStripeFailure() {
    AppEnvironment.with(\.stripe.updateSubscription .~ { _, _, _, _ in throwE(unit) }) {
      let conn = connection(from: request(to: .account(.subscription(.reactivate)), session: .loggedIn))
      let result = conn |> siteMiddleware

      assertSnapshot(matching: result.perform())
    }
  }

  func testReactivateEmail() {
    let doc = reactivateEmailView.view((.mock, .mock)).first!

    assertSnapshot(matching: render(doc, config: pretty), pathExtension: "html")
    assertSnapshot(matching: plainText(for: doc))

    #if !os(Linux)
      if #available(OSX 10.13, *) {
        let webView = WKWebView(frame: .init(x: 0, y: 0, width: 800, height: 800))
        webView.loadHTMLString(render(doc), baseURL: nil)
        assertSnapshot(matching: webView)

        webView.frame.size = .init(width: 400, height: 700)
        assertSnapshot(matching: webView)
      }
    #endif
  }
}
