import { WebPlugin } from '@capacitor/core';
import type { NtpRawResponse, RawNtpPlugin } from './definitions';
export declare class RawNtpWeb extends WebPlugin implements RawNtpPlugin {
    request(): Promise<NtpRawResponse>;
}
