export interface NtpRequestOptions {
    /** NTP server hostname or IP. Default: "pool.ntp.org" */
    host?: string;
    /** UDP port. Default: 123 */
    port?: number;
    /** Milliseconds to wait for the reply. Default: 5000 */
    timeout?: number;
    /**
     * Optional: base64 of the exact bytes to send.
     * Default: 48-byte SNTP client request (0x1B followed by 47 zero bytes).
     */
    requestPacket?: string;
}
export interface NtpRawResponse {
    /** UDP payload exactly as received from the server, base64 encoded. */
    packet: string;
    /** IP address of the server that replied. */
    address: string;
    /** T1: device wall clock (Unix epoch ms) captured immediately before send. */
    t1: number;
    /** T4: device wall clock (Unix epoch ms) captured immediately after receive. */
    t4: number;
    /** Monotonic clock (ns) captured at the same moment as t1. Use with t4Mono for the round-trip interval. */
    t1Mono: number;
    /** Monotonic clock (ns) captured at the same moment as t4. */
    t4Mono: number;
}
export interface RawNtpPlugin {
    request(options?: NtpRequestOptions): Promise<NtpRawResponse>;
}
