import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let content = bestAttemptContent else {
      contentHandler(request.content)
      return
    }

    let userInfo = content.userInfo
    let messageType =
      ((userInfo["message_kind"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
      ?? ((userInfo["message_type"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
    let titleFull = (userInfo["title_full"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let bodyFull = (userInfo["body_full"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let textBody = (userInfo["text_body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let caption = (userInfo["caption"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let roomId = (userInfo["room_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let titleFull, !titleFull.isEmpty {
      content.title = titleFull
    }

    if let bodyFull, !bodyFull.isEmpty {
      content.body = bodyFull
    } else if messageType == "image_feed" {
      if let caption, !caption.isEmpty {
        content.body = "🖼️ \(caption)"
      } else if let textBody, !textBody.isEmpty {
        content.body = "🖼️ \(textBody)"
      } else {
        content.body = "🖼️"
      }
    } else if let textBody, !textBody.isEmpty {
      content.body = textBody
    }

    if let roomId, !roomId.isEmpty {
      content.threadIdentifier = "room_\(roomId)"
    }

    contentHandler(content)
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler, let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
