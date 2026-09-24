import { WebPlugin } from '@capacitor/core';

import type { NtpRawResponse, RawNtpPlugin } from './definitions';

export class RawNtpWeb extends WebPlugin implements RawNtpPlugin {
  async request(): Promise<NtpRawResponse> {
    throw this.unavailable('UDP sockets are not available in browsers.');
  }
}
