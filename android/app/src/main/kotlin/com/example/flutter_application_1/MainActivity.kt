package com.example.flutter_application_1

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import de.blinkt.openvpn.VpnProfile
import de.blinkt.openvpn.core.ConfigParser
import de.blinkt.openvpn.core.ProfileManager
import de.blinkt.openvpn.core.VPNLaunchHelper
import de.blinkt.openvpn.core.OpenVPNService
import de.blinkt.openvpn.core.VpnStatus
import de.blinkt.openvpn.core.ConnectionStatus

import java.io.StringReader

class MainActivity: FlutterActivity(), VpnStatus.StateListener, VpnStatus.ByteCountListener {

    private val METHOD_CHANNEL = "vpnControl"
    private val STAGE_CHANNEL = "vpnStage"
    private val STATUS_CHANNEL = "vpnStatus"

    private var vpnConfig: String? = null
    private val VPN_REQUEST_CODE = 24

    private var stageSink: EventChannel.EventSink? = null
    private var statusSink: EventChannel.EventSink? = null

    private var lastState = "disconnected"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "start" -> {
                        vpnConfig = call.argument("config")
                        prepareVpn()
                        result.success("Preparing")
                    }

                    "stop" -> {
                        stopVpn()
                        result.success("Stopped")
                    }

                    "stage" -> {
                        result.success(lastState)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STAGE_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    stageSink = events
                }

                override fun onCancel(arguments: Any?) {
                    stageSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STATUS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    statusSink = events
                }

                override fun onCancel(arguments: Any?) {
                    statusSink = null
                }
            })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        VpnStatus.addStateListener(this)
        VpnStatus.addByteCountListener(this)
    }

    override fun onDestroy() {
        super.onDestroy()

        VpnStatus.removeStateListener(this)
        VpnStatus.removeByteCountListener(this)
    }

    override fun updateState(
        state: String?,
        logmessage: String?,
        localizedResId: Int,
        level: ConnectionStatus?,
        intent: Intent?
    ) {

        Handler(Looper.getMainLooper()).post {

            lastState = when (state) {
                "CONNECTED" -> "connected"
                "DISCONNECTED" -> "disconnected"
                "WAIT", "RESOLVE", "TCP_CONNECT" -> "wait_connection"
                "AUTH" -> "authenticating"
                "RECONNECTING" -> "reconnect"
                "NONETWORK" -> "no_connection"
                "CONNECTING" -> "connecting"
                else -> "prepare"
            }

            stageSink?.success(lastState)
        }
    }

    override fun setConnectedVPN(uuid: String?) {}

    override fun updateByteCount(inBytes: Long, outBytes: Long, diffIn: Long, diffOut: Long) {

        Handler(Looper.getMainLooper()).post {

            val jsonStr =
                """{"byte_in":"${formatBytes(inBytes)}", "byte_out":"${formatBytes(outBytes)}"}"""

            statusSink?.success(jsonStr)
        }
    }

    private fun formatBytes(bytes: Long): String {

        if (bytes < 1024) return "$bytes B"

        val kb = bytes / 1024
        if (kb < 1024) return "$kb KB"

        val mb = kb / 1024
        return "$mb MB"
    }

    private fun prepareVpn() {

        val intent = VpnService.prepare(this)

        if (intent != null) {
            startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            startVpnService()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {

        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            startVpnService()
        }
    }

    private fun startVpnService() {

        val configText = vpnConfig ?: return

        try {

            val cp = ConfigParser()
            cp.parseConfig(StringReader(configText))

            val vp: VpnProfile = cp.convertProfile()

            val pm = ProfileManager.getInstance(this)

            pm.addProfile(vp)
            pm.saveProfile(this, vp)

            ProfileManager.setConnectedVpnProfile(this, vp)

            VPNLaunchHelper.startOpenVpn(vp, this)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopVpn() {

        try {

            val intent = Intent(this, OpenVPNService::class.java)

            stopService(intent)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}