package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.ws.WebSocketSessions;
import java.util.HashMap;
import java.util.Map;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class NotificationDispatcher {
    private final WebSocketSessions sessions;
    private final FcmClient fcm;

    public NotificationDispatcher(WebSocketSessions sessions, FcmClient fcm) {
        this.sessions = sessions;
        this.fcm = fcm;
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(UserEvent event) {
        if (event.payload() != null) {
            sessions.sendToUser(event.userId(), event.payload());
        }
        if (event.pushTitle() != null && event.fcmToken() != null && !event.fcmToken().isBlank()) {
            Map<String, String> data = new HashMap<>();
            if (event.payload() != null) {
                event.payload().forEach((k, v) -> {
                    if (v != null) data.put(k, String.valueOf(v));
                });
            }
            fcm.send(event.fcmToken(), event.pushTitle(), event.pushBody(), data);
        }
    }
}
