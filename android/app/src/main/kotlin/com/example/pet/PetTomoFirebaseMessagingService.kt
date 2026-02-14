package com.example.pet

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.Drawable
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.toBitmap
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.net.HttpURLConnection
import java.net.URL

class PetTomoFirebaseMessagingService : FirebaseMessagingService() {
    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        if (data.isEmpty()) {
            return
        }
        showMessagingNotification(data)
    }

    private fun showMessagingNotification(data: Map<String, String>) {
        val roomId = data["room_id"]?.takeIf { it.isNotBlank() } ?: "room_default"
        val messageId = data["message_id"]?.takeIf { it.isNotBlank() }
        val messageType = data["message_kind"]?.takeIf { it.isNotBlank() }
            ?: data["message_type"]?.takeIf { it.isNotBlank() }
            ?: "text"
        val title = data["title_full"]?.takeIf { it.isNotBlank() } ?: "PetTomo"
        val petName = data["pet_name"]?.takeIf { it.isNotBlank() } ?: "Pet"
        val senderName = data["sender_name"]?.takeIf { it.isNotBlank() } ?: "Someone"
        val contentText = resolveBody(messageType = messageType, data = data)
        val largeIcon = composeLargeIcon(resolvePetAvatarBitmap(data))
        val conversationUser = NotificationCompat.Person.Builder()
            .setName(petName)
            .setIcon(androidx.core.graphics.drawable.IconCompat.createWithBitmap(largeIcon))
            .build()
        val senderPerson = NotificationCompat.Person.Builder()
            .setName(senderName)
            .build()

        val style = NotificationCompat.MessagingStyle(conversationUser)
            .setConversationTitle(title)
            .addMessage(contentText, System.currentTimeMillis(), senderPerson)

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launchIntent.putExtra("room_id", roomId)
        launchIntent.putExtra("message_id", messageId)
        launchIntent.putExtra("message_type", messageType)
        launchIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP

        val pendingIntent = PendingIntent.getActivity(
            this,
            roomId.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notificationId = roomId.hashCode()
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(contentText)
            .setStyle(style)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setOnlyAlertOnce(false)
            .setContentIntent(pendingIntent)
            .setGroup("pettomo_room_$roomId")
            .setLargeIcon(largeIcon)
            .build()

        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }

    private fun resolveBody(messageType: String, data: Map<String, String>): String {
        val bodyFull = data["body_full"]?.trim().orEmpty()
        if (bodyFull.isNotEmpty()) {
            return bodyFull
        }
        return if (messageType == "image_feed") {
            val caption = data["caption"]?.trim().orEmpty()
            if (caption.isNotEmpty()) {
                "🖼️ $caption"
            } else {
                val fallback = data["text_body"]?.trim().orEmpty()
                if (fallback.isNotEmpty()) "🖼️ $fallback" else "🖼️"
            }
        } else {
            data["text_body"]?.trim().takeUnless { it.isNullOrEmpty() } ?: "New message"
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            channelId,
            "Feed Notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Foreground and background notifications for chat and feed events."
        }
        manager.createNotificationChannel(channel)
    }

    private fun resolvePetAvatarBitmap(data: Map<String, String>): Bitmap? {
        val petType = normalizePetType(data["pet_type"])
        val primaryUrl = data["pet_avatar_url"]?.takeIf { it.isNotBlank() }
        val fallbackUrl = data["pet_avatar_fallback_url"]?.takeIf { it.isNotBlank() }
        val explicitAsset = data["pet_avatar_asset"]?.takeIf { it.isNotBlank() }
        val fallbackAsset = petAvatarAssetByType[petType]

        return primaryUrl?.let(::downloadBitmap)
            ?: explicitAsset?.let(::loadBitmapFromFlutterAsset)
            ?: fallbackAsset?.let(::loadBitmapFromFlutterAsset)
            ?: fallbackUrl?.let(::downloadBitmap)
    }

    private fun normalizePetType(raw: String?): String {
        val normalized = raw?.trim()?.lowercase().orEmpty()
        return if (normalized in petAvatarAssetByType.keys) normalized else defaultPetType
    }

    private fun composeLargeIcon(avatarBitmap: Bitmap?): Bitmap {
        val base = avatarBitmap?.let { cropCircle(it) } ?: drawableToBitmap(R.mipmap.ic_launcher)
        val badge = drawableToBitmap(R.drawable.ic_notification)
        return overlayBadge(base, badge)
    }

    private fun downloadBitmap(urlString: String): Bitmap? {
        return try {
            val connection = (URL(urlString).openConnection() as HttpURLConnection).apply {
                connectTimeout = 3000
                readTimeout = 3000
                instanceFollowRedirects = true
            }
            connection.inputStream.use { input ->
                BitmapFactory.decodeStream(input)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun loadBitmapFromFlutterAsset(assetPath: String): Bitmap? {
        val normalizedPath = assetPath.removePrefix("/")
        val flutterAssetPath = if (normalizedPath.startsWith("flutter_assets/")) {
            normalizedPath
        } else {
            "flutter_assets/$normalizedPath"
        }
        return try {
            assets.open(flutterAssetPath).use { input ->
                BitmapFactory.decodeStream(input)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun cropCircle(source: Bitmap): Bitmap {
        val size = minOf(source.width, source.height)
        val left = (source.width - size) / 2
        val top = (source.height - size) / 2
        val squared = Bitmap.createBitmap(source, left, top, size, size)

        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = Rect(0, 0, size, size)
        val rectF = RectF(rect)
        canvas.drawOval(rectF, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(squared, rect, rect, paint)
        return output
    }

    private fun drawableToBitmap(drawableId: Int): Bitmap {
        val drawable: Drawable = checkNotNull(getDrawable(drawableId))
        val size = 192
        return drawable.toBitmap(width = size, height = size, config = Bitmap.Config.ARGB_8888)
    }

    private fun overlayBadge(base: Bitmap, badge: Bitmap): Bitmap {
        val output = base.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(output)
        val badgeSize = (output.width * 0.32f).toInt().coerceAtLeast(36)
        val inset = (output.width * 0.04f).toInt()
        val left = output.width - badgeSize - inset
        val top = output.height - badgeSize - inset
        val dst = Rect(left, top, left + badgeSize, top + badgeSize)
        canvas.drawBitmap(badge, null, dst, null)
        return output
    }

    companion object {
        private const val channelId = "feed_notifications"
        private const val defaultPetType = "ghost"
        private val petAvatarAssetByType = mapOf(
            "cat" to "assets/pet/cat/cat_stay.gif",
            "fish" to "assets/pet/fish/fish_stay.gif",
            "ghost" to "assets/pet/ghost/ghost_stay.gif",
        )
    }
}
