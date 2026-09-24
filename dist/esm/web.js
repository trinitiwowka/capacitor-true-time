import { WebPlugin } from '@capacitor/core';
export class RawNtpWeb extends WebPlugin {
    async request() {
        throw this.unavailable('UDP sockets are not available in browsers.');
    }
}
