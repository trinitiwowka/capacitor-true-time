/** Options for native NTP time synchronization. */
export interface TrueTimeOptions {
    /** DNS name or IP address of an NTP server. */
    host: string;
    /** Android query timeout in milliseconds, clamped to 500...10000. iOS uses TrueTime.swift's default timeout. */
    timeoutMs?: number;
}
/** Identity returned by the native implementation. */
export interface TrueTimeImplementationInfo {
    implementation: '@trinitiwowka/capacitor-true-time';
    implementationVersion: '1.0.3';
    signature: 'capacitor-true-time-native-sntp-v1';
    protocol: 'NTPv3' | 'SNTPv4';
}
/** Corrected UTC and legacy-compatible timestamps in Unix milliseconds. */
export interface TrueTimeResult extends TrueTimeImplementationInfo {
    /** Corrected UTC time at callback on iOS or packet receipt on Android. */
    callback: number;
    /** Client request transmission time. */
    t0: number;
    /** Server request receipt time on Android; corrected callback time on iOS. */
    t1: number;
    /** Server response transmission time on Android; corrected callback time on iOS. */
    t2: number;
    /** Client response receipt time. */
    t3: number;
    /** Network round-trip delay on Android; half the native call duration on iOS, matching the old plugin. */
    delay: number;
    /** Estimated local-clock offset from the server. */
    offset: number;
    /** Server root delay from its primary reference clock. */
    rootDelay?: number;
    /** Server root dispersion from its primary reference clock. */
    rootDispersion?: number;
    host: string;
    stratum?: number;
    leap?: number;
}
export interface TrueTimePlugin {
    /** Get corrected time from the original TrueTime.swift client on iOS or an SNTP sample on Android. */
    getTime(options: TrueTimeOptions): Promise<TrueTimeResult>;
    /** Return stable identifiers for the native code loaded by Capacitor. */
    getImplementationInfo(): Promise<TrueTimeImplementationInfo>;
}
