package com.music.bitchord.platform

import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.NSProcessInfo

@OptIn(BetaInteropApi::class, ExperimentalForeignApi::class)
actual object PlatformInfo {
    actual val name: String = when {
        NSProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != null -> "ios-simulator"
        else -> "ios"
    }
    actual val isApple: Boolean = true
}
