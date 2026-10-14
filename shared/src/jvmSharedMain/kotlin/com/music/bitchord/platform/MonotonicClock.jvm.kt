package com.music.bitchord.platform

actual fun monotonicNowMs(): Long = System.nanoTime() / 1_000_000L
