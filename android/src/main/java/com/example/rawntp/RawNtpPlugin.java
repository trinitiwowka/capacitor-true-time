package com.example.rawntp;

import android.util.Base64;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@CapacitorPlugin(name = "RawNtp")
public class RawNtpPlugin extends Plugin {

    private final ExecutorService executor = Executors.newCachedThreadPool();

    @PluginMethod
    public void request(PluginCall call) {
        final String host = call.getString("host", "pool.ntp.org");
        final int port = call.getInt("port", 123);
        final int timeout = call.getInt("timeout", 5000);

        final byte[] requestBytes;
        String custom = call.getString("requestPacket");
        if (custom != null) {
            try {
                requestBytes = Base64.decode(custom, Base64.DEFAULT);
            } catch (IllegalArgumentException e) {
                call.reject("requestPacket is not valid base64", "BAD_INPUT");
                return;
            }
        } else {
            requestBytes = new byte[48];
            requestBytes[0] = 0x1B; // LI=0, VN=3, Mode=3 (client)
        }

        executor.execute(() -> {
            DatagramSocket socket = null;
            try {
                InetAddress address = InetAddress.getByName(host);
                socket = new DatagramSocket();
                socket.setSoTimeout(timeout);
                socket.connect(address, port); // only accept replies from this peer

                DatagramPacket request = new DatagramPacket(requestBytes, requestBytes.length);
                byte[] buffer = new byte[2048]; // room for NTP extension fields
                DatagramPacket response = new DatagramPacket(buffer, buffer.length);

                long t1Mono = System.nanoTime();
                long t1 = System.currentTimeMillis();
                socket.send(request);

                socket.receive(response);
                long t4Mono = System.nanoTime();
                long t4 = System.currentTimeMillis();

                byte[] raw = Arrays.copyOf(response.getData(), response.getLength());

                JSObject result = new JSObject();
                result.put("packet", Base64.encodeToString(raw, Base64.NO_WRAP));
                result.put("address", response.getAddress().getHostAddress());
                result.put("t1", t1);
                result.put("t4", t4);
                result.put("t1Mono", t1Mono);
                result.put("t4Mono", t4Mono);
                call.resolve(result);
            } catch (SocketTimeoutException e) {
                call.reject("Timed out waiting for NTP response", "TIMEOUT", e);
            } catch (UnknownHostException e) {
                call.reject("Could not resolve host: " + host, "DNS", e);
            } catch (Exception e) {
                call.reject("NTP request failed: " + e.getMessage(), "IO", e);
            } finally {
                if (socket != null) socket.close();
            }
        });
    }

    @Override
    protected void handleOnDestroy() {
        executor.shutdownNow();
        super.handleOnDestroy();
    }
}
