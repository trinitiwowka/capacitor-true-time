import { registerPlugin } from '@capacitor/core';
const TrueTime = registerPlugin('TrueTime', {
    web: () => import('./web').then((module) => new module.TrueTimeWeb()),
});
export * from './definitions';
export { TrueTime };
//# sourceMappingURL=index.js.map