'use strict';

var core = require('@capacitor/core');

const TrueTime = core.registerPlugin('TrueTime', {
    web: () => Promise.resolve().then(function () { return web; }).then((module) => new module.TrueTimeWeb()),
});

class TrueTimeWeb extends core.WebPlugin {
    async getTime() {
        throw this.unavailable('Native SNTP is available only on iOS and Android');
    }
    async getImplementationInfo() {
        throw this.unavailable('Native SNTP is available only on iOS and Android');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    TrueTimeWeb: TrueTimeWeb
});

exports.TrueTime = TrueTime;
//# sourceMappingURL=plugin.cjs.js.map
