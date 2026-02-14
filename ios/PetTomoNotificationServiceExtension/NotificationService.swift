import UserNotifications
import UIKit
import Intents

final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?
  private let defaultPetType = "ghost"
  private let petAvatarFallbackByType: [String: String] = [
    "cat": "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/cat_stay.gif",
    "fish": "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/fish_stay.gif",
    "ghost": "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/ghost_stay.gif",
  ]

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
    let petName = (userInfo["pet_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

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

    let group = DispatchGroup()
    var attachments: [UNNotificationAttachment] = []
    var communicationAvatarImage: UIImage?

    let petAvatarUrl = resolvePetAvatarURL(from: userInfo)
    let imageUrl = (userInfo["image_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let petAvatar = petAvatarUrl {
      group.enter()
      loadImage(from: petAvatar) { [weak self] avatarImage in
        defer { group.leave() }
        communicationAvatarImage = avatarImage
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
      if let communicationContent = self.buildCommunicationContent(
        from: content,
        roomId: roomId,
        petName: petName,
        avatarImage: communicationAvatarImage
      ) {
        contentHandler(communicationContent)
        return
      }
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

  private func resolvePetAvatarURL(from userInfo: [AnyHashable: Any]) -> URL? {
    if let primary = trimmedString(userInfo["pet_avatar_url"]), let url = URL(string: primary) {
      return url
    }
    if let explicitFallback = trimmedString(userInfo["pet_avatar_fallback_url"]),
      let url = URL(string: explicitFallback)
    {
      return url
    }
    let petType = normalizePetType(trimmedString(userInfo["pet_type"]))
    guard let mapped = petAvatarFallbackByType[petType] else {
      return nil
    }
    return URL(string: mapped)
  }

  private func trimmedString(_ value: Any?) -> String? {
    guard let string = value as? String else {
      return nil
    }
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func normalizePetType(_ value: String?) -> String {
    let normalized = value?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if petAvatarFallbackByType[normalized] != nil {
      return normalized
    }
    return defaultPetType
  }

  private func buildCommunicationContent(
    from content: UNMutableNotificationContent,
    roomId: String?,
    petName: String?,
    avatarImage: UIImage?
  ) -> UNMutableNotificationContent? {
    guard #available(iOS 15.0, *) else {
      return nil
    }

    let resolvedPetName = (petName?.isEmpty == false) ? petName! : "Pet"
    let senderHandle = INPersonHandle(value: "pet:\(resolvedPetName)", type: .unknown)
    let senderImage = avatarImage.flatMap { image in
      image.pngData().flatMap { INImage(imageData: $0) }
    }
    let sender = INPerson(
      personHandle: senderHandle,
      nameComponents: nil,
      displayName: resolvedPetName,
      image: senderImage,
      contactIdentifier: nil,
      customIdentifier: "pet_sender"
    )

    let me = INPerson(
      personHandle: INPersonHandle(value: "current_user", type: .unknown),
      nameComponents: nil,
      displayName: nil,
      image: nil,
      contactIdentifier: nil,
      customIdentifier: "self"
    )

    let intent = INSendMessageIntent(
      recipients: [me],
      outgoingMessageType: .outgoingMessageText,
      content: content.body,
      speakableGroupName: nil,
      conversationIdentifier: roomId,
      serviceName: "PetTomo",
      sender: sender
    )
    intent.setImage(senderImage, forParameterNamed: \INSendMessageIntent.sender)

    let interaction = INInteraction(intent: intent, response: nil)
    interaction.donate { _ in }

    do {
      return try content.updating(from: intent) as? UNMutableNotificationContent
    } catch {
      return nil
    }
  }
}
