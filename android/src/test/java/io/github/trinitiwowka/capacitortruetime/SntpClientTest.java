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
        assertEquals(5, sample.rootDelay, 0.01);
        assertEquals(10, sample.rootDispersion, 0.01);
        assertEquals(2, sample.stratum);
    }

    @Test
    public void calculatesCorrectedTimeWithClockOffset() {
        double t0 = 1_700_000_000_000.0;
        double t1 = t0 + 32;
        double t2 = t0 + 34;
        double t3 = t0 + 26;
        byte[] request = SntpClient.createRequest(t0);

        SntpClient.Sample sample = SntpClient.parseResponse(request, validResponse(request, t1, t2), t0, t3);

        assertEquals(24, sample.delay, 0.01);
        assertEquals(20, sample.offset, 0.01);
        assertEquals(t3 + 20, sample.t3 + sample.offset, 0.01);
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

    @Test
    public void rejectsMissingReferenceTimestamp() {
        double t0 = 1_700_000_000_000.0;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(request, t0 + 12, t0 + 14);
        Arrays.fill(response, 16, 24, (byte) 0);

        assertThrows(IllegalArgumentException.class, () -> SntpClient.parseResponse(request, response, t0, t0 + 26));
    }

    @Test
    public void rejectsExcessiveRoundTripDelay() {
        double t0 = 1_700_000_000_000.0;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(request, t0 + 12, t0 + 14);

        assertThrows(IllegalArgumentException.class, () -> SntpClient.parseResponse(request, response, t0, t0 + 752));
    }

    @Test
    public void rejectsExcessiveRootDispersion() {
        double t0 = 1_700_000_000_000.0;
        byte[] request = SntpClient.createRequest(t0);
        byte[] response = validResponse(request, t0 + 12, t0 + 14);
        writeShortFixed(response, 8, 101);

        assertThrows(IllegalArgumentException.class, () -> SntpClient.parseResponse(request, response, t0, t0 + 26));
    }

    private static byte[] validResponse(byte[] request, double t1, double t2) {
        byte[] response = new byte[48];
        response[0] = 0x24; // leap 0, version 4, server mode 4
        response[1] = 2;
        writeShortFixed(response, 4, 5);
        writeShortFixed(response, 8, 10);
        SntpClient.writeTimestamp(response, 16, t1 - 1_000);
        System.arraycopy(Arrays.copyOfRange(request, 40, 48), 0, response, 24, 8);
        SntpClient.writeTimestamp(response, 32, t1);
        SntpClient.writeTimestamp(response, 40, t2);
        return response;
    }

    private static void writeShortFixed(byte[] data, int offset, double milliseconds) {
        long bits = Math.round(milliseconds * 65.536);
        data[offset] = (byte) (bits >>> 24);
        data[offset + 1] = (byte) (bits >>> 16);
        data[offset + 2] = (byte) (bits >>> 8);
        data[offset + 3] = (byte) bits;
    }
}
