package br.edu.ifsp.doa.api.security;

import br.edu.ifsp.doa.api.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwt;
    private final TokenBlacklist blacklist;
    private final UserRepository users;

    public JwtAuthFilter(JwtService jwt, TokenBlacklist blacklist, UserRepository users) {
        this.jwt = jwt;
        this.blacklist = blacklist;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                Claims claims = jwt.parse(header.substring(7));
                if (!blacklist.isRevoked(claims.getId())) {
                    users.findById(Long.valueOf(claims.getSubject()))
                        .filter(u -> u.isActive())
                        .ifPresent(u -> {
                            var auth = new UsernamePasswordAuthenticationToken(
                                new AuthUser(u.getId(), u.getEmail(), u.getRole()),
                                null,
                                List.of(new SimpleGrantedAuthority("ROLE_" + u.getRole().name())));
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
                }
            } catch (JwtException | IllegalArgumentException ignored) {
                // token inválido: segue sem autenticação e o entry point responde 401
            }
        }
        chain.doFilter(request, response);
    }
}
