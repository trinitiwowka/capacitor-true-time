import { registerPlugin } from '@capacitor/core';

import type { NtpRawResponse, NtpRequestOptions, RawNtpPlugin } from './definitions';

const RawNtp = registerPlugin<RawNtpPlugin>('RawNtp', {
  web: () => import('./web').then((m) => new m.RawNtpWeb()),
});

/** Callback-style wrapper around RawNtp.request(). */
export function requestNtp(
  options: NtpRequestOptions,
  callback: (error: Error | null, result?: NtpRawResponse) => void,
): void {
  RawNtp.request(options).then(
    (result) => callback(null, result),
    (error) => callback(error instanceof Error ? error : new Error(String(error))),
  );
}

export * from './definitions';
export { RawNtp };
