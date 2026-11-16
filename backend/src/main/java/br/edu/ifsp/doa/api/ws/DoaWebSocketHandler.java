package br.edu.ifsp.doa.api.ws;

import br.edu.ifsp.doa.api.domain.UserRole;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.ChatService;
import br.edu.ifsp.doa.api.web.ApiException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/**
 * Protocolo (JSON):
 *  cliente -> servidor: {"type":"chat","donationId":10,"content":"Oi"} | {"type":"ping"}
 *  servidor -> cliente: {"type":"connected"} | {"type":"chat",...} | {"type":"notification",...} |
 *                       {"type":"error","message":"..."} | {"type":"pong"}
 */
@Component
public class DoaWebSocketHandler extends TextWebSocketHandler {
    private static final Logger log = LoggerFactory.getLogger(DoaWebSocketHandler.class);

    private final WebSocketSessions sessions;
    private final ChatService chat;
    private final ObjectMapper mapper;

    public DoaWebSocketHandler(WebSocketSessions sessions, ChatService chat, ObjectMapper mapper) {
        this.sessions = sessions;
        this.chat = chat;
        this.mapper = mapper;
    }

    private Long userId(WebSocketSession s) {
        return (Long) s.getAttributes().get("userId");
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.add(userId(session), session);
        sessions.send(session, Map.of("type", "connected", "userId", userId(session)));
        log.info("WebSocket conectado: usuário {}", userId(session));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            JsonNode node = mapper.readTree(message.getPayload());
            String type = node.path("type").asText("");
            AuthUser user = new AuthUser(
                userId(session),
                (String) session.getAttributes().get("email"),
                (UserRole) session.getAttributes().get("role"));

            switch (type) {
                case "chat" -> chat.send(user, node.path("donationId").asLong(), node.path("content").asText(""));
                case "ping" -> sessions.send(session, Map.of("type", "pong"));
                default -> sessions.send(session, Map.of("type", "error", "message", "Tipo de mensagem desconhecido."));
            }
        } catch (ApiException ex) {
            sessions.send(session, Map.of("type", "error", "message", ex.getMessage()));
        } catch (Exception ex) {
            sessions.send(session, Map.of("type", "error", "message", "Mensagem inválida."));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(userId(session), session);
        log.info("WebSocket desconectado: usuário {}", userId(session));
    }
}
