/** Options for a single SNTP query. */
export interface TrueTimeOptions {
  /** DNS name or IP address of an NTP server. */
  host: string;
  /** Query timeout in milliseconds. Values are clamped to 500...10000. */
  timeoutMs?: number;
}

/** Identity returned by the native implementation. */
export interface TrueTimeImplementationInfo {
  implementation: '@trinitiwowka/capacitor-true-time';
  implementationVersion: '1.0.2';
  signature: 'capacitor-true-time-native-sntp-v1';
  protocol: 'SNTPv4';
}

/** A validated four-timestamp SNTP sample. All timestamps are Unix milliseconds. */
export interface TrueTimeResult extends TrueTimeImplementationInfo {
  /** Corrected UTC time at receipt (`t3 + offset`). */
  callback: number;
  /** Client request transmission time. */
  t0: number;
  /** Server request receipt time. */
  t1: number;
  /** Server response transmission time. */
  t2: number;
  /** Client response receipt time. */
  t3: number;
  /** Network round-trip delay. */
  delay: number;
  /** Estimated local-clock offset from the server. */
  offset: number;
  /** Server root delay from its primary reference clock. */
  rootDelay: number;
  /** Server root dispersion from its primary reference clock. */
  rootDispersion: number;
  host: string;
  stratum: number;
  leap: number;
}

export interface TrueTimePlugin {
  /** Query an NTP server and return a validated sample (best of four on iOS). */
  getTime(options: TrueTimeOptions): Promise<TrueTimeResult>;

  /** Return stable identifiers for the native code loaded by Capacitor. */
  getImplementationInfo(): Promise<TrueTimeImplementationInfo>;
}
