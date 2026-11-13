package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.UserRole;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class UserDtos {
    private UserDtos() {}

    public record UserCreateRequest(
        @NotBlank(message = "Informe o e-mail.") @Email(message = "E-mail inválido.") String email,
        @NotBlank(message = "Informe a senha.")
        @Size(min = 6, message = "A senha deve ter ao menos 6 caracteres.") String password,
        @NotNull(message = "Informe o perfil.") UserRole role) {}

    /** Todos os campos são opcionais: só o que vier preenchido é alterado. */
    public record UserUpdateRequest(
        @Email(message = "E-mail inválido.") String email,
        UserRole role,
        @JsonProperty("isActive") Boolean active,
        @Size(min = 6, message = "A senha deve ter ao menos 6 caracteres.") String password) {}

    public record FcmTokenRequest(@NotBlank(message = "Informe o token.") String token) {}
}
