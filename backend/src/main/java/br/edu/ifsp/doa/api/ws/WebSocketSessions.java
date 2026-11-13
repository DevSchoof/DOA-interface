package br.edu.ifsp.doa.api.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

/** Sessões WebSocket abertas, agrupadas por usuário (o mesmo usuário pode ter várias abas). */
@Component
public class WebSocketSessions {
    private static final Logger log = LoggerFactory.getLogger(WebSocketSessions.class);

    private final Map<Long, Set<WebSocketSession>> byUser = new ConcurrentHashMap<>();
    private final ObjectMapper mapper;

    public WebSocketSessions(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public void add(Long userId, WebSocketSession session) {
        byUser.computeIfAbsent(userId, k -> new CopyOnWriteArraySet<>()).add(session);
    }

    public void remove(Long userId, WebSocketSession session) {
        Set<WebSocketSession> set = byUser.get(userId);
        if (set != null) {
            set.remove(session);
            if (set.isEmpty()) byUser.remove(userId);
        }
    }

    public void sendToUser(Long userId, Map<String, Object> payload) {
        Set<WebSocketSession> set = byUser.get(userId);
        if (set == null) return;
        for (WebSocketSession session : set) {
            send(session, payload);
        }
    }

    public void send(WebSocketSession session, Map<String, Object> payload) {
        try {
            String json = mapper.writeValueAsString(payload);
            synchronized (session) { // WebSocketSession não aceita envios simultâneos
                if (session.isOpen()) {
                    session.sendMessage(new TextMessage(json));
                }
            }
        } catch (Exception ex) {
            log.warn("Falha ao enviar pelo WebSocket: {}", ex.getMessage());
        }
    }
}
