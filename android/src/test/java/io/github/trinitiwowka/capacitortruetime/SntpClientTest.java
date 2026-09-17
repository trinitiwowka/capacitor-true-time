package io.github.trinitiwowka.capacitortruetime;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

import java.util.Arrays;
import org.junit.Test;

public class SntpClientTest {

    @Test
    public void parsesFourTimestampSample() {
        double t0 = 1_700_000_000_000.0;
        double t1 = t0 + 12;
        double t2 = t0 + 14;
        double t3 = t0 + 26;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(request, t1, t2);

        SntpClient.Sample sample = SntpClient.parseResponse(request, response, t0, t3);

        assertEquals(24, sample.delay, 0.01);
        assertEquals(0, sample.offset, 0.01);
        assertEquals(2, sample.stratum);
    }

    @Test
    public void rejectsResponseForAnotherRequest() {
        double t0 = 1_700_000_000_000.0;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(SntpClient.createRequest(t0 + 1_000), t0 + 12, t0 + 14);

        assertThrows(IllegalArgumentException.class, () -> SntpClient.parseResponse(request, response, t0, t0 + 26));
    }

    @Test
    public void rejectsUnsynchronizedServer() {
        double t0 = 1_700_000_000_000.0;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(request, t0 + 12, t0 + 14);
        response[0] = (byte) 0xe4;

        assertThrows(IllegalArgumentException.class, () -> SntpClient.parseResponse(request, response, t0, t0 + 26));
    }

    private static byte[] validResponse(byte[] request, double t1, double t2) {
        byte[] response = new byte[48];
        response[0] = 0x24; // leap 0, version 4, server mode 4
        response[1] = 2;
        System.arraycopy(Arrays.copyOfRange(request, 40, 48), 0, response, 24, 8);
        SntpClient.writeTimestamp(response, 32, t1);
        SntpClient.writeTimestamp(response, 40, t2);
        return response;
    }
}
