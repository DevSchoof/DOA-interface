package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.User;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

@Component
public class Notifier {
    private final ApplicationEventPublisher publisher;

    public Notifier(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    /** Notificação: WebSocket (se conectado) e push (se o usuário registrou token). */
    public void notify(User user, String title, String body, Map<String, Object> data) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", "notification");
        payload.put("title", title);
        payload.put("body", body);
        payload.putAll(data);
        publisher.publishEvent(new UserEvent(user.getId(), user.getFcmToken(), payload, title, body));
    }

    /** Só WebSocket (ex.: eco da mensagem do chat para quem enviou). */
    public void websocketOnly(User user, Map<String, Object> payload) {
        publisher.publishEvent(new UserEvent(user.getId(), null, payload, null, null));
    }

    /** WebSocket com um payload próprio e push (ex.: nova mensagem do chat). */
    public void websocketAndPush(User user, Map<String, Object> payload, String title, String body) {
        publisher.publishEvent(new UserEvent(user.getId(), user.getFcmToken(), payload, title, body));
    }
}
