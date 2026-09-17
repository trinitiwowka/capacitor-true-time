package io.github.trinitiwowka.capacitortruetime;

import android.os.SystemClock;
import com.getcapacitor.JSObject;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.util.Arrays;

final class SntpClient {

    private static final double NTP_EPOCH_OFFSET_SECONDS = 2_208_988_800.0;
    private static final double FRACTION_SCALE = 4_294_967_296.0;
    private static final int NTP_PORT = 123;
    private static final int PACKET_SIZE = 48;

    private SntpClient() {}

    static Sample request(String host, int timeoutMs) throws Exception {
        InetAddress address = InetAddress.getByName(host);
        byte[] request = createRequest(System.currentTimeMillis());
        double t0 = readTimestamp(request, 40);

        try (DatagramSocket socket = new DatagramSocket()) {
            socket.connect(address, NTP_PORT);
            socket.setSoTimeout(timeoutMs);

            DatagramPacket requestPacket = new DatagramPacket(request, request.length, address, NTP_PORT);
            long requestElapsedNanos = SystemClock.elapsedRealtimeNanos();
            socket.send(requestPacket);

            byte[] responseBuffer = new byte[512];
            DatagramPacket responsePacket = new DatagramPacket(responseBuffer, responseBuffer.length);
            socket.receive(responsePacket);
            long responseElapsedNanos = SystemClock.elapsedRealtimeNanos();

            double t3 = t0 + (responseElapsedNanos - requestElapsedNanos) / 1_000_000.0;
            byte[] response = Arrays.copyOf(responsePacket.getData(), responsePacket.getLength());
            return parseResponse(request, response, t0, t3);
        }
    }

    static byte[] createRequest(double unixTimeMs) {
        byte[] request = new byte[PACKET_SIZE];
        request[0] = 0x23; // leap 0, SNTP version 4, client mode 3
        writeTimestamp(request, 40, unixTimeMs);
        return request;
    }

    static Sample parseResponse(byte[] request, byte[] response, double t0, double t3) {
        if (response.length < PACKET_SIZE) {
            throw new IllegalArgumentException("Invalid NTP response: packet is shorter than 48 bytes");
        }

        int leap = (response[0] >> 6) & 0x03;
        int version = (response[0] >> 3) & 0x07;
        int mode = response[0] & 0x07;
        int stratum = response[1] & 0xff;

        if (leap == 3) throw new IllegalArgumentException("Invalid NTP response: server clock is unsynchronized");
        if (version < 3 || version > 4) throw new IllegalArgumentException("Invalid NTP response: unsupported protocol version");
        if (mode != 4) throw new IllegalArgumentException("Invalid NTP response: response is not in server mode");
        if (stratum < 1 || stratum > 15) throw new IllegalArgumentException("Invalid NTP response: invalid stratum");

        if (!Arrays.equals(Arrays.copyOfRange(request, 40, 48), Arrays.copyOfRange(response, 24, 32))) {
            throw new IllegalArgumentException("Invalid NTP response: origin timestamp does not match the request");
        }

        double t1 = readTimestamp(response, 32);
        double t2 = readTimestamp(response, 40);
        if (t1 <= 0 || t2 <= 0) {
            throw new IllegalArgumentException("Invalid NTP response: server timestamps are missing");
        }

        double rawDelay = t3 - t0 - (t2 - t1);
        if (rawDelay < -1_000 || rawDelay > 10_000) {
            throw new IllegalArgumentException("Invalid NTP response: round-trip delay is outside the accepted range");
        }

        double delay = Math.max(0, rawDelay);
        double offset = (t1 - t0 + (t2 - t3)) / 2.0;
        return new Sample(t0, t1, t2, t3, delay, offset, stratum, leap);
    }

    static void writeTimestamp(byte[] data, int offset, double unixMs) {
        double ntpSeconds = unixMs / 1_000.0 + NTP_EPOCH_OFFSET_SECONDS;
        long seconds = (long) Math.floor(ntpSeconds);
        long fraction = (long) ((ntpSeconds - Math.floor(ntpSeconds)) * FRACTION_SCALE);
        writeUnsignedInt(data, offset, seconds);
        writeUnsignedInt(data, offset + 4, fraction);
    }

    static double readTimestamp(byte[] data, int offset) {
        long seconds = readUnsignedInt(data, offset);
        long fraction = readUnsignedInt(data, offset + 4);
        return (seconds - NTP_EPOCH_OFFSET_SECONDS + fraction / FRACTION_SCALE) * 1_000.0;
    }

    private static void writeUnsignedInt(byte[] data, int offset, long value) {
        data[offset] = (byte) (value >>> 24);
        data[offset + 1] = (byte) (value >>> 16);
        data[offset + 2] = (byte) (value >>> 8);
        data[offset + 3] = (byte) value;
    }

    private static long readUnsignedInt(byte[] data, int offset) {
        return (
            (((long) data[offset] & 0xff) << 24) |
            (((long) data[offset + 1] & 0xff) << 16) |
            (((long) data[offset + 2] & 0xff) << 8) |
            ((long) data[offset + 3] & 0xff)
        );
    }

    static final class Sample {

        final double t0;
        final double t1;
        final double t2;
        final double t3;
        final double delay;
        final double offset;
        final int stratum;
        final int leap;

        Sample(double t0, double t1, double t2, double t3, double delay, double offset, int stratum, int leap) {
            this.t0 = t0;
            this.t1 = t1;
            this.t2 = t2;
            this.t3 = t3;
            this.delay = delay;
            this.offset = offset;
            this.stratum = stratum;
            this.leap = leap;
        }

        JSObject toJSObject(String host) {
            JSObject result = new JSObject();
            result.put("callback", t3 + offset);
            result.put("t0", t0);
            result.put("t1", t1);
            result.put("t2", t2);
            result.put("t3", t3);
            result.put("delay", delay);
            result.put("offset", offset);
            result.put("host", host);
            result.put("stratum", stratum);
            result.put("leap", leap);
            return result;
        }
    }
}
