package com.music.bitchord.platform

/** Small platform boundary used by shared code without depending on Android or JVM APIs. */
expect object PlatformInfo {
    val name: String
    val isApple: Boolean
}
