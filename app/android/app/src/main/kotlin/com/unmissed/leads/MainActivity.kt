package com.unmissed.leads

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // --- Standard leads channel ---
            val leadsChannel = NotificationChannel(
                "leads",
                "New Leads",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for new incoming leads"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(leadsChannel)

            // --- Urgent leads channel — loud alarm sound, bypasses DND ---
            val urgentSoundUri: Uri = try {
                // Try to use custom sound from res/raw/urgent_alarm.mp3
                Uri.parse("android.resource://${packageName}/raw/urgent_alarm")
            } catch (_: Exception) {
                // Fallback to system alarm ringtone (loud by default)
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            }

            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val urgentChannel = NotificationChannel(
                "urgent_leads",
                "🚨 Urgent / Emergency Leads",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Loud alarm for urgent and emergency leads — overrides Do Not Disturb"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500, 200, 500)
                setSound(urgentSoundUri, audioAttributes)
                setBypassDnd(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
            }
            notificationManager.createNotificationChannel(urgentChannel)
        }
    }
}
