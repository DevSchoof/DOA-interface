package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.domain.UserRole;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public final class AuthDtos {
    private AuthDtos() {}

    public record LoginRequest(
        @NotBlank(message = "Informe o e-mail.") String email,
        @NotBlank(message = "Informe a senha.") String password) {}

    public record RegisterRequest(
        @NotBlank(message = "Informe o e-mail.") @Email(message = "E-mail inválido.") String email,
        @NotBlank(message = "Informe a senha.")
        @Size(min = 6, message = "A senha deve ter ao menos 6 caracteres.") String password,
        @NotNull(message = "Informe o perfil.") UserRole role) {}

    public record UserResponse(
        Long id,
        String email,
        UserRole role,
        @JsonProperty("isActive") boolean active,
        LocalDateTime createdAt) {
        public static UserResponse from(User u) {
            return new UserResponse(u.getId(), u.getEmail(), u.getRole(), u.isActive(), u.getCreatedAt());
        }
    }

    public record AuthResponse(String token, UserResponse user) {}
}
