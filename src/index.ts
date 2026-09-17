import { registerPlugin } from '@capacitor/core';

import type { TrueTimePlugin } from './definitions';

const TrueTime = registerPlugin<TrueTimePlugin>('TrueTime', {
  web: () => import('./web').then((module) => new module.TrueTimeWeb()),
});

export * from './definitions';
export { TrueTime };
