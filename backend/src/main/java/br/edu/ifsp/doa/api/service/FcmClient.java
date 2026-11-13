package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.GoogleCredentials;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Envia push pela API HTTP v1 do Firebase Cloud Messaging.
 * Sem credenciais configuradas, fica desligado (só registra em log).
 */
@Component
public class FcmClient {
    private static final Logger log = LoggerFactory.getLogger(FcmClient.class);
    private static final String SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

    private final RestClient http = RestClient.create();
    private GoogleCredentials credentials;
    private String projectId;

    public FcmClient(AppProperties props, ObjectMapper mapper) {
        try {
            String json = props.fcm().credentialsJson();
            String path = props.fcm().credentialsPath();
            if ((json == null || json.isBlank()) && path != null && !path.isBlank()) {
                json = Files.readString(Path.of(path));
            }
            if (json == null || json.isBlank()) {
                log.info("FCM desativado: nenhuma credencial configurada.");
                return;
            }
            this.projectId = mapper.readTree(json).get("project_id").asText();
            this.credentials = GoogleCredentials
                .fromStream(new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)))
                .createScoped(List.of(SCOPE));
            log.info("FCM ativado para o projeto {}.", projectId);
        } catch (Exception ex) {
            log.warn("Não foi possível iniciar o FCM; push desativado: {}", ex.getMessage());
            this.credentials = null;
        }
    }

    public boolean enabled() {
        return credentials != null;
    }

    public void send(String token, String title, String body, Map<String, String> data) {
        if (!enabled()) {
            log.debug("Push ignorado (FCM desativado): {}", title);
            return;
        }
        try {
            credentials.refreshIfExpired();
            String access = credentials.getAccessToken().getTokenValue();
            Map<String, Object> message = Map.of("message", Map.of(
                "token", token,
                "notification", Map.of("title", title, "body", body == null ? "" : body),
                "data", data));
            http.post()
                .uri("https://fcm.googleapis.com/v1/projects/{project}/messages:send", projectId)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + access)
                .contentType(MediaType.APPLICATION_JSON)
                .body(message)
                .retrieve()
                .toBodilessEntity();
        } catch (Exception ex) {
            log.warn("Falha ao enviar push: {}", ex.getMessage());
        }
    }
}
