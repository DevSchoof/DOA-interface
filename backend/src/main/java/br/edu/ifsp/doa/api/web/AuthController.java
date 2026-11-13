package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.service.AuthService;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.AuthResponse;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.LoginRequest;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.RegisterRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return auth.login(request);
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return auth.register(request);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestHeader(value = "Authorization", required = false) String header) {
        if (header != null && header.startsWith("Bearer ")) {
            auth.logout(header.substring(7));
        }
        return ResponseEntity.noContent().build();
    }
}
