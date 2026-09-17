import { WebPlugin } from '@capacitor/core';
import type { TrueTimeImplementationInfo, TrueTimePlugin, TrueTimeResult } from './definitions';
export declare class TrueTimeWeb extends WebPlugin implements TrueTimePlugin {
    getTime(): Promise<TrueTimeResult>;
    getImplementationInfo(): Promise<TrueTimeImplementationInfo>;
}
