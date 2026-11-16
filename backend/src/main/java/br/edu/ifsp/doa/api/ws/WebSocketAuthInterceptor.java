package br.edu.ifsp.doa.api.ws;

import br.edu.ifsp.doa.api.repository.UserRepository;
import br.edu.ifsp.doa.api.security.JwtService;
import br.edu.ifsp.doa.api.security.TokenBlacklist;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriComponentsBuilder;

/** Valida o JWT enviado como ?token=... na abertura da conexão. */
@Component
public class WebSocketAuthInterceptor implements HandshakeInterceptor {
    private final JwtService jwt;
    private final TokenBlacklist blacklist;
    private final UserRepository users;

    public WebSocketAuthInterceptor(JwtService jwt, TokenBlacklist blacklist, UserRepository users) {
        this.jwt = jwt;
        this.blacklist = blacklist;
        this.users = users;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler handler, Map<String, Object> attributes) {
        String token = UriComponentsBuilder.fromUri(request.getURI()).build().getQueryParams().getFirst("token");
        if (token != null) {
            try {
                Claims claims = jwt.parse(token);
                if (!blacklist.isRevoked(claims.getId())) {
                    var user = users.findById(Long.valueOf(claims.getSubject())).filter(u -> u.isActive());
                    if (user.isPresent()) {
                        attributes.put("userId", user.get().getId());
                        attributes.put("email", user.get().getEmail());
                        attributes.put("role", user.get().getRole());
                        return true;
                    }
                }
            } catch (JwtException | IllegalArgumentException ignored) {
                // cai no 401 abaixo
            }
        }
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        return false;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler handler, Exception exception) {
        // nada a fazer
    }
}
