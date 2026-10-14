# BitChord iOS host

This directory contains the first iOS host target and an unsigned-IPA GitHub Actions workflow.

The current host is intentionally a compileable SwiftUI shell. The full Android UI and playback stack is not yet available on iOS: the existing Kotlin UI is hosted in `jvmSharedMain`, while playback is implemented with Android Media3/JNI. The next migration step is to move platform-neutral UI into `commonMain` and implement AVFoundation-backed playback, background audio, media controls, Keychain, file access, and OAuth adapters.

The `ios.yml` workflow produces an **unsigned IPA** for sideload tooling such as AltStore/Sideloadly. It is not directly installable on a stock iPhone until the sideload tool re-signs it with the user's Apple Account.
