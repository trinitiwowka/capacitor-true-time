# @trinitiwowka/capacitor-true-time

Raw UDP NTP requests for Capacitor 8 on iOS and Android. Each call sends one packet to the selected server and returns its response bytes and local send/receive timestamps. The plugin does not cache, parse, validate, or adjust the device clock. Applications decide how to validate samples and use them for synchronization.

Version 2.0.0 replaces the `TrueTime.getTime()` API from 1.x with `RawNtp.request()`. This is the native request implementation used by the Jamables 2.1.0 raw NTP test build.

## Requirements

- Capacitor 8
- iOS 14 or newer
- Android API 23 or newer; Java 21 for Android builds
- Node.js 22 or newer for package development

## Install

```sh
npm install @trinitiwowka/capacitor-true-time@^2.0.1
npx cap sync
```

The package supports CocoaPods and Swift Package Manager on iOS.

## Usage

```ts
import { RawNtp } from '@trinitiwowka/capacitor-true-time';

const sample = await RawNtp.request({ host: 'time.google.com', timeout: 3000 });
console.log(sample.packet, sample.t1, sample.t4, sample.t1Mono, sample.t4Mono);
```

`packet` is the base64-encoded UDP response. `t1` and `t4` are local Unix milliseconds measured before sending and after receiving. `t1Mono` and `t4Mono` are monotonic nanoseconds measured at the same points. `address` is the responding IP address. Options also include `port` (default 123) and `requestPacket` (base64 bytes to send); without `requestPacket`, the plugin sends a 48-byte NTPv3 client request.

The response is deliberately raw. Before using it as a clock sample, the application should validate the NTP packet, calculate delay and offset, and reject unsuitable responses. A network may block UDP port 123, so requests can time out.

The web implementation reports `unavailable` because browsers cannot open raw UDP sockets.
