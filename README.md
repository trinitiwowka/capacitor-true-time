# @trinitiwowka/capacitor-true-time

Native NTP time synchronization for Capacitor 8 on iOS and Android. iOS uses the original Instacart TrueTime.swift clock and a thin Capacitor wrapper. Android uses a validated SNTP exchange with the same corrected-UTC result shape.

The iOS TrueTime.swift sources come from [Instacart commit `14c2d65`](https://github.com/instacart/TrueTime.swift/commit/14c2d65) under Apache-2.0. The few compatibility changes needed for Swift Package Manager and Xcode 26 are kept in `ios/Vendor/TrueTime`.

## Requirements

- Capacitor 8
- Node.js 22 or newer for development
- iOS 15 or newer, built with Xcode 26 or newer
- Android API 24 or newer, compiled and targeted with API 36
- Java 21 for Android builds

## Install from GitHub

```bash
npm install @trinitiwowka/capacitor-true-time@1.0.3
npx cap sync
```

The npm package supports both CocoaPods and Swift Package Manager on iOS.

## Usage

```ts
import { TrueTime } from '@trinitiwowka/capacitor-true-time';

const sample = await TrueTime.getTime({
  host: 'time.google.com',
  timeoutMs: 3000,
});

console.log({
  correctedUtcMs: sample.callback,
  roundTripDelayMs: sample.delay,
  clockOffsetMs: sample.offset,
});
```

All timestamps are Unix milliseconds:

- `t0`: client request transmission
- `t1`: server request receipt on Android; corrected callback time on iOS
- `t2`: server response transmission on Android; corrected callback time on iOS
- `t3`: client response receipt
- `delay`: NTP round trip on Android; half the native call duration on iOS, as in the old Cordova wrapper
- `offset`: estimated difference between corrected UTC and device time
- `callback`: corrected UTC at packet receipt on Android or callback time on iOS

The response also carries a stable implementation name, version, and identifier so an app can verify which native implementation is loaded:

```ts
const info = await TrueTime.getImplementationInfo();
// {
//   implementation: '@trinitiwowka/capacitor-true-time',
//   implementationVersion: '1.0.3',
//   signature: 'capacitor-true-time-native-sntp-v1',
//   protocol: 'NTPv3' // iOS; Android reports 'SNTPv4'
// }
```

The identifier is an implementation marker, not a cryptographic signature.

## Validation and timing behavior

On iOS, TrueTime.swift resolves the chosen host, samples each address four times, selects its lowest-delay response, takes the median clock offset across addresses, and maintains a corrected clock using device uptime. Its default internal refresh is 512 seconds. The Capacitor wrapper keeps the old Cordova response fields, including the cached reference on subsequent calls.

As in the old Cordova wrapper, iOS starts with the first requested host and then uses its cached reference; the `host` field echoes the requested argument and does not identify the server used by that cached reference.

On Android, each call makes one SNTPv4 request to the selected host, as the old Android wrapper did. The client validates the response origin and server state, rejects large delays, and uses elapsed realtime to avoid wall-clock changes during the exchange. The application can compare responses from several hosts. Coordinating audio on the common UTC timeline remains application logic.

SNTP uses UDP port 123. Some networks block that traffic, so applications should use a timeout, keep more than one server available, and handle a rejected promise.

The web implementation reports `unavailable`; browsers do not provide raw UDP sockets.

## API

<docgen-index>

* [`getTime(...)`](#gettime)
* [`getImplementationInfo()`](#getimplementationinfo)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### getTime(...)

```typescript
getTime(options: TrueTimeOptions) => Promise<TrueTimeResult>
```

Get corrected time from the original TrueTime.swift client on iOS or an SNTP sample on Android.

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`options`** | <code><a href="#truetimeoptions">TrueTimeOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#truetimeresult">TrueTimeResult</a>&gt;</code>

--------------------


### getImplementationInfo()

```typescript
getImplementationInfo() => Promise<TrueTimeImplementationInfo>
```

Return stable identifiers for the native code loaded by Capacitor.

**Returns:** <code>Promise&lt;<a href="#truetimeimplementationinfo">TrueTimeImplementationInfo</a>&gt;</code>

--------------------


### Interfaces


#### TrueTimeResult

Corrected UTC and legacy-compatible timestamps in Unix milliseconds.

| Prop                 | Type                | Description                                                                                         |
| -------------------- | ------------------- | --------------------------------------------------------------------------------------------------- |
| **`callback`**       | <code>number</code> | Corrected UTC time at callback on iOS or packet receipt on Android.                                 |
| **`t0`**             | <code>number</code> | Client request transmission time.                                                                   |
| **`t1`**             | <code>number</code> | Server request receipt time on Android; corrected callback time on iOS.                             |
| **`t2`**             | <code>number</code> | Server response transmission time on Android; corrected callback time on iOS.                       |
| **`t3`**             | <code>number</code> | Client response receipt time.                                                                       |
| **`delay`**          | <code>number</code> | Network round-trip delay on Android; half the native call duration on iOS, matching the old plugin. |
| **`offset`**         | <code>number</code> | Estimated local-clock offset from the server.                                                       |
| **`rootDelay`**      | <code>number</code> | Server root delay from its primary reference clock.                                                 |
| **`rootDispersion`** | <code>number</code> | Server root dispersion from its primary reference clock.                                            |
| **`host`**           | <code>string</code> |                                                                                                     |
| **`stratum`**        | <code>number</code> |                                                                                                     |
| **`leap`**           | <code>number</code> |                                                                                                     |


#### TrueTimeOptions

Options for native NTP time synchronization.

| Prop            | Type                | Description                                                                                               |
| --------------- | ------------------- | --------------------------------------------------------------------------------------------------------- |
| **`host`**      | <code>string</code> | DNS name or IP address of an NTP server.                                                                  |
| **`timeoutMs`** | <code>number</code> | Android query timeout in milliseconds, clamped to 500...10000. iOS uses TrueTime.swift's default timeout. |


#### TrueTimeImplementationInfo

Identity returned by the native implementation.

| Prop                        | Type                                              |
| --------------------------- | ------------------------------------------------- |
| **`implementation`**        | <code>'@trinitiwowka/capacitor-true-time'</code>  |
| **`implementationVersion`** | <code>'1.0.3'</code>                              |
| **`signature`**             | <code>'capacitor-true-time-native-sntp-v1'</code> |
| **`protocol`**              | <code>'NTPv3' \| 'SNTPv4'</code>                  |

</docgen-api>

## License

MIT
