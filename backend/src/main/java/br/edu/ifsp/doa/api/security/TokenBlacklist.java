package br.edu.ifsp.doa.api.security;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Tokens invalidados pelo logout (PB-002). Fica em memória: é suficiente para
 * uma instância só; em produção com várias instâncias use Redis ou tabela.
 */
@Component
public class TokenBlacklist {
    private final Map<String, Instant> revoked = new ConcurrentHashMap<>();

    public void revoke(String jti, Instant expiresAt) {
        Instant now = Instant.now();
        revoked.entrySet().removeIf(e -> e.getValue().isBefore(now)); // limpeza
        revoked.put(jti, expiresAt);
    }

    public boolean isRevoked(String jti) {
        return jti != null && revoked.containsKey(jti);
    }
}
