import UserNotifications
import UIKit

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
    let messageType = (userInfo["message_type"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let titleFull = (userInfo["title_full"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let textBody = (userInfo["text_body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let caption = (userInfo["caption"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let roomId = (userInfo["room_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let senderName = (userInfo["sender_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let titleFull, !titleFull.isEmpty {
      content.title = titleFull
    }
    if let senderName, !senderName.isEmpty {
      content.subtitle = senderName
    }

    if messageType == "image_feed" {
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

    let group = DispatchGroup()
    var attachments: [UNNotificationAttachment] = []

    let petAvatarUrl = (userInfo["pet_avatar_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let imageUrl = (userInfo["image_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let petAvatarUrl, let petAvatar = URL(string: petAvatarUrl), !petAvatarUrl.isEmpty {
      group.enter()
      loadImage(from: petAvatar) { [weak self] avatarImage in
        defer { group.leave() }
        guard
          let self,
          let avatarImage,
          let composed = self.composeAvatarWithBadge(avatar: avatarImage),
          let attachment = self.imageAttachment(from: composed, identifier: "pet_avatar")
        else {
          return
        }
        attachments.append(attachment)
      }
    }

    if messageType == "image_feed",
      let imageUrl,
      let feedImageUrl = URL(string: imageUrl),
      !imageUrl.isEmpty
    {
      group.enter()
      loadImage(from: feedImageUrl) { [weak self] feedImage in
        defer { group.leave() }
        guard
          let self,
          let feedImage,
          let attachment = self.imageAttachment(from: feedImage, identifier: "feed_image")
        else {
          return
        }
        attachments.append(attachment)
      }
    }

    group.notify(queue: .main) {
      content.attachments = attachments
      contentHandler(content)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler, let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data, let image = UIImage(data: data) else {
        completion(nil)
        return
      }
      completion(image)
    }
    task.resume()
  }

  private func composeAvatarWithBadge(avatar: UIImage) -> UIImage? {
    let size = CGSize(width: 240, height: 240)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { _ in
      let avatarRect = CGRect(origin: .zero, size: size)
      UIBezierPath(ovalIn: avatarRect).addClip()
      avatar.draw(in: avatarRect)

      guard let badge = UIImage(named: "AppBadge") else {
        return
      }

      let badgeSize = size.width * 0.34
      let inset = size.width * 0.04
      let badgeRect = CGRect(
        x: size.width - badgeSize - inset,
        y: size.height - badgeSize - inset,
        width: badgeSize,
        height: badgeSize
      )

      let circle = UIBezierPath(ovalIn: badgeRect)
      UIColor.white.setFill()
      circle.fill()

      badge.draw(in: badgeRect.insetBy(dx: 4, dy: 4))
    }
  }

  private func imageAttachment(from image: UIImage, identifier: String) -> UNNotificationAttachment? {
    let fileName = "\(identifier)-\(UUID().uuidString).png"
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let fileURL = tempDirectory.appendingPathComponent(fileName)

    guard let pngData = image.pngData() else {
      return nil
    }

    do {
      try pngData.write(to: fileURL)
      return try UNNotificationAttachment(identifier: identifier, url: fileURL)
    } catch {
      return nil
    }
  }
}
