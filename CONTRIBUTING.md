# Contributing

Use Node.js 22 or newer, Java 21, and the Android SDK for native builds.

```sh
npm ci
npm run build
npm run verify:android
```

The iOS source is under `ios/Sources/RawNtpPlugin/`. Validate native changes with a Capacitor 8 iOS app build. `npm pack --dry-run` shows the files included in the public package.

The GitHub release workflow publishes a matching `vX.Y.Z` tag to npm. Keep `package.json` and `package-lock.json` versions aligned before creating a release.
