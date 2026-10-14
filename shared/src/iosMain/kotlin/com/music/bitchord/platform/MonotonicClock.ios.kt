package com.music.bitchord.platform

import platform.Foundation.NSProcessInfo

actual fun monotonicNowMs(): Long =
    (NSProcessInfo.processInfo.systemUptime * 1_000.0).toLong()
