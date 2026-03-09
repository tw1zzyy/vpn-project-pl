package com.example.flutter_application_1

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
// ADD THIS IMPORT
import de.blinkt.openvpn.core.OpenVPNService 

class MainActivity: FlutterActivity() {
    private val CHANNEL = "vpnControl"
    private var vpnConfig: String? = null
    private val VPN_REQUEST_CODE = 24

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    vpnConfig = call.argument("config")
                    prepareVpn()
                    result.success("Preparing...")
                }
                "stop" -> {
                    stopVpn()
                    result.success("Stopped")
                }
                "stage" -> {
                    result.success("disconnected") 
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareVpn() {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            onActivityResult(VPN_REQUEST_CODE, Activity.RESULT_OK, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            startVpnService()
        }
    }

    private fun startVpnService() {
        if (vpnConfig == null) return

        // FIX: Use the correct class from your vpnLib
        val intent = Intent(this, OpenVPNService::class.java)
        intent.putExtra("config", vpnConfig)
        intent.action = "start" 
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVpn() {
        val intent = Intent(this, OpenVPNService::class.java)
        intent.action = "stop"
        startService(intent)
    }
}