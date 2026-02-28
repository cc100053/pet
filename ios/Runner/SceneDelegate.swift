import Flutter
import SafariServices
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private let oauthCallbackScheme = "com.cc100053.pet"
  private let oauthCallbackHost = "login-callback"

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard shouldHandleOAuthCallback(URLContexts) else {
      return
    }
    dismissPresentedSafariController(in: scene)
  }

  private func shouldHandleOAuthCallback(_ contexts: Set<UIOpenURLContext>) -> Bool {
    return contexts.contains { context in
      let url = context.url
      return url.scheme?.lowercased() == oauthCallbackScheme &&
        url.host?.lowercased() == oauthCallbackHost
    }
  }

  private func dismissPresentedSafariController(in scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }
    for window in windowScene.windows {
      guard var top = window.rootViewController else {
        continue
      }
      while let presented = top.presentedViewController {
        top = presented
      }
      if top is SFSafariViewController {
        top.dismiss(animated: true)
      }
    }
  }
}
