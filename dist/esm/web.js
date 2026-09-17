import { WebPlugin } from '@capacitor/core';
export class TrueTimeWeb extends WebPlugin {
    async getTime() {
        throw this.unavailable('Native SNTP is available only on iOS and Android');
    }
    async getImplementationInfo() {
        throw this.unavailable('Native SNTP is available only on iOS and Android');
    }
}
//# sourceMappingURL=web.js.map