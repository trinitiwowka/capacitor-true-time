import { registerPlugin } from '@capacitor/core';
const RawNtp = registerPlugin('RawNtp', {
    web: () => import('./web').then((m) => new m.RawNtpWeb()),
});
/** Callback-style wrapper around RawNtp.request(). */
export function requestNtp(options, callback) {
    RawNtp.request(options).then((result) => callback(null, result), (error) => callback(error instanceof Error ? error : new Error(String(error))));
}
export * from './definitions';
export { RawNtp };
