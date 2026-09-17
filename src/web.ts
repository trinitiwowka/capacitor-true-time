import { WebPlugin } from '@capacitor/core';

import type { TrueTimeImplementationInfo, TrueTimePlugin, TrueTimeResult } from './definitions';

export class TrueTimeWeb extends WebPlugin implements TrueTimePlugin {
  async getTime(): Promise<TrueTimeResult> {
    throw this.unavailable('Native SNTP is available only on iOS and Android');
  }

  async getImplementationInfo(): Promise<TrueTimeImplementationInfo> {
    throw this.unavailable('Native SNTP is available only on iOS and Android');
  }
}
