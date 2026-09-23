# @trinitiwowka/capacitor-true-time

Native SNTPv4 time synchronization for Capacitor 8 on iOS and Android. The plugin performs the network exchange in native code and returns the four timestamps needed to calculate delay, clock offset, and corrected UTC time.

It has no dependency on the archived Cordova TrueTime plugin or the TrueTime Swift package.

## Requirements

- Capacitor 8
- Node.js 22 or newer for development
- iOS 15 or newer, built with Xcode 26 or newer
- Android API 24 or newer, compiled and targeted with API 36
- Java 21 for Android builds

## Install from GitHub

```bash
npm install github:trinitiwowka/capacitor-true-time#v1.0.2
npx cap sync
```

The package is ready for npm publication under the `@trinitiwowka` scope as well.

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
- `t1`: server request receipt
- `t2`: server response transmission
- `t3`: client response receipt
- `delay`: `(t3 - t0) - (t2 - t1)`
- `offset`: `((t1 - t0) + (t2 - t3)) / 2`
- `callback`: corrected UTC at receipt, `t3 + offset`

The response also carries a stable implementation name, version, and identifier so an app can verify which native implementation is loaded:

```ts
const info = await TrueTime.getImplementationInfo();
// {
//   implementation: '@trinitiwowka/capacitor-true-time',
//   implementationVersion: '1.0.2',
//   signature: 'capacitor-true-time-native-sntp-v1',
//   protocol: 'SNTPv4'
// }
```

The identifier is an implementation marker, not a cryptographic signature.

## Validation and timing behavior

The native clients reject short packets, unsupported NTP versions, non-server responses, unsynchronized clocks, invalid strata, missing timestamps, root delay or dispersion above 100 ms, round trips of 750 ms or more, and responses whose origin timestamp does not match the request. Elapsed time during each exchange comes from the platform monotonic clock, so a wall-clock adjustment during the request does not corrupt `t3`.

On iOS, each call checks four responses and returns the lowest-delay valid sample, following the sampling used by the earlier TrueTime.swift integration. Android makes one request per call, as the earlier Android integration did. The caller selects the NTP host and can query several hosts, compare samples, and keep the lowest-delay result. Coordinating audio or other events on the resulting common UTC timeline remains application logic.

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

Query an NTP server and return a validated sample (best of four on iOS).

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

A validated four-timestamp SNTP sample. All timestamps are Unix milliseconds.

| Prop                 | Type                | Description                                              |
| -------------------- | ------------------- | -------------------------------------------------------- |
| **`callback`**       | <code>number</code> | Corrected UTC time at receipt (`t3 + offset`).           |
| **`t0`**             | <code>number</code> | Client request transmission time.                        |
| **`t1`**             | <code>number</code> | Server request receipt time.                             |
| **`t2`**             | <code>number</code> | Server response transmission time.                       |
| **`t3`**             | <code>number</code> | Client response receipt time.                            |
| **`delay`**          | <code>number</code> | Network round-trip delay.                                |
| **`offset`**         | <code>number</code> | Estimated local-clock offset from the server.            |
| **`rootDelay`**      | <code>number</code> | Server root delay from its primary reference clock.      |
| **`rootDispersion`** | <code>number</code> | Server root dispersion from its primary reference clock. |
| **`host`**           | <code>string</code> |                                                          |
| **`stratum`**        | <code>number</code> |                                                          |
| **`leap`**           | <code>number</code> |                                                          |


#### TrueTimeOptions

Options for a single SNTP query.

| Prop            | Type                | Description                                                       |
| --------------- | ------------------- | ----------------------------------------------------------------- |
| **`host`**      | <code>string</code> | DNS name or IP address of an NTP server.                          |
| **`timeoutMs`** | <code>number</code> | Query timeout in milliseconds. Values are clamped to 500...10000. |


#### TrueTimeImplementationInfo

Identity returned by the native implementation.

| Prop                        | Type                                              |
| --------------------------- | ------------------------------------------------- |
| **`implementation`**        | <code>'@trinitiwowka/capacitor-true-time'</code>  |
| **`implementationVersion`** | <code>'1.0.2'</code>                              |
| **`signature`**             | <code>'capacitor-true-time-native-sntp-v1'</code> |
| **`protocol`**              | <code>'SNTPv4'</code>                             |

</docgen-api>

## License

MIT
