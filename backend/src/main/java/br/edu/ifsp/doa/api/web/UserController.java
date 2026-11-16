package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.UserService;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.UserResponse;
import br.edu.ifsp.doa.api.web.dto.UserDtos.FcmTokenRequest;
import br.edu.ifsp.doa.api.web.dto.UserDtos.UserCreateRequest;
import br.edu.ifsp.doa.api.web.dto.UserDtos.UserUpdateRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService users;

    public UserController(UserService users) {
        this.users = users;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal AuthUser user) {
        return users.me(user.id());
    }

    /** O app registra aqui o token do Firebase para receber push. */
    @PutMapping("/me/fcm-token")
    public ResponseEntity<Void> fcmToken(@AuthenticationPrincipal AuthUser user,
                                         @Valid @RequestBody FcmTokenRequest request) {
        users.setFcmToken(user.id(), request.token());
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody UserCreateRequest request) {
        return users.create(request);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<UserResponse> list() {
        return users.list();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse get(@PathVariable Long id) {
        return users.get(id);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse update(@PathVariable Long id, @Valid @RequestBody UserUpdateRequest request) {
        return users.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id, @AuthenticationPrincipal AuthUser user) {
        users.delete(id, user.id());
        return ResponseEntity.noContent().build();
    }
}
