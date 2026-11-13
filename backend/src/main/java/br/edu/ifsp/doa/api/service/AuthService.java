package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.domain.UserRole;
import br.edu.ifsp.doa.api.repository.UserRepository;
import br.edu.ifsp.doa.api.security.JwtService;
import br.edu.ifsp.doa.api.security.TokenBlacklist;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.AuthResponse;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.LoginRequest;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.RegisterRequest;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.UserResponse;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import java.time.LocalDateTime;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private static final int MAX_ATTEMPTS = 3;
    private static final int LOCK_MINUTES = 30;

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final TokenBlacklist blacklist;

    public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt, TokenBlacklist blacklist) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
        this.blacklist = blacklist;
    }

    /** noRollbackFor: o contador de tentativas precisa ser gravado mesmo quando o login falha. */
    @Transactional(noRollbackFor = ApiException.class)
    public AuthResponse login(LoginRequest request) {
        User user = users.findByEmailIgnoreCase(request.email().trim())
            .orElseThrow(() -> ApiException.unauthorized("E-mail ou senha inválidos."));

        if (user.getLockedUntil() != null && user.getLockedUntil().isAfter(LocalDateTime.now())) {
            throw ApiException.forbidden("Conta bloqueada por 30 minutos após 3 tentativas erradas.");
        }

        if (!encoder.matches(request.password(), user.getPasswordHash())) {
            user.setFailedAttempts(user.getFailedAttempts() + 1);
            if (user.getFailedAttempts() >= MAX_ATTEMPTS) {
                user.setLockedUntil(LocalDateTime.now().plusMinutes(LOCK_MINUTES));
                user.setFailedAttempts(0);
            }
            throw ApiException.unauthorized("E-mail ou senha inválidos.");
        }

        if (!user.isActive()) {
            throw ApiException.forbidden("Conta suspensa. Contate o administrador.");
        }

        user.setFailedAttempts(0);
        user.setLockedUntil(null);
        return new AuthResponse(jwt.generate(user), UserResponse.from(user));
    }

    /** Cadastro público: só doador e instituição. Já devolve a sessão (token). */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (request.role() != UserRole.DONOR && request.role() != UserRole.INSTITUTION) {
            throw ApiException.forbidden("Este perfil não pode ser criado no cadastro público.");
        }
        String email = request.email().trim().toLowerCase();
        if (users.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("Já existe um usuário com este e-mail.");
        }
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(request.password()));
        user.setRole(request.role());
        users.save(user);
        return new AuthResponse(jwt.generate(user), UserResponse.from(user));
    }

    public void logout(String token) {
        try {
            Claims claims = jwt.parse(token);
            blacklist.revoke(claims.getId(), claims.getExpiration().toInstant());
        } catch (JwtException | IllegalArgumentException ignored) {
            // token já inválido: nada a revogar
        }
    }
}
