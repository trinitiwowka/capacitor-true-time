import type { NtpRawResponse, NtpRequestOptions, RawNtpPlugin } from './definitions';
declare const RawNtp: RawNtpPlugin;
/** Callback-style wrapper around RawNtp.request(). */
export declare function requestNtp(options: NtpRequestOptions, callback: (error: Error | null, result?: NtpRawResponse) => void): void;
export * from './definitions';
export { RawNtp };
