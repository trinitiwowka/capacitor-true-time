package io.github.trinitiwowka.capacitortruetime;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@CapacitorPlugin(name = "TrueTime")
public class TrueTimePlugin extends Plugin {

    static final String IMPLEMENTATION = "@trinitiwowka/capacitor-true-time";
    static final String VERSION = "1.0.2";
    static final String SIGNATURE = "capacitor-true-time-native-sntp-v1";
    static final String PROTOCOL = "SNTPv4";

    private final ExecutorService executor = Executors.newCachedThreadPool();

    @PluginMethod
    public void getTime(PluginCall call) {
        String rawHost = call.getString("host");
        if (rawHost == null || rawHost.trim().isEmpty()) {
            call.reject("An NTP host is required");
            return;
        }

        String host = rawHost.trim();
        Integer requestedTimeout = call.getInt("timeoutMs");
        int timeoutMs = Math.min(Math.max(requestedTimeout == null ? 3_000 : requestedTimeout, 500), 10_000);

        executor.execute(() -> {
            try {
                SntpClient.Sample sample = SntpClient.request(host, timeoutMs);
                JSObject result = sample.toJSObject(host);
                addIdentity(result);
                call.resolve(result);
            } catch (Exception error) {
                call.reject(error.getMessage(), error);
            }
        });
    }

    @PluginMethod
    public void getImplementationInfo(PluginCall call) {
        JSObject result = new JSObject();
        addIdentity(result);
        call.resolve(result);
    }

    @Override
    protected void handleOnDestroy() {
        executor.shutdownNow();
    }

    private static void addIdentity(JSObject result) {
        result.put("implementation", IMPLEMENTATION);
        result.put("implementationVersion", VERSION);
        result.put("signature", SIGNATURE);
        result.put("protocol", PROTOCOL);
    }
}
