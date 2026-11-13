package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.repository.DonorRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.repository.UserRepository;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.AuthDtos.UserResponse;
import br.edu.ifsp.doa.api.web.dto.UserDtos.UserCreateRequest;
import br.edu.ifsp.doa.api.web.dto.UserDtos.UserUpdateRequest;
import java.util.List;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class UserService {
    private final UserRepository users;
    private final DonorRepository donors;
    private final InstitutionRepository institutions;
    private final PasswordEncoder encoder;

    public UserService(UserRepository users, DonorRepository donors, InstitutionRepository institutions,
                       PasswordEncoder encoder) {
        this.users = users;
        this.donors = donors;
        this.institutions = institutions;
        this.encoder = encoder;
    }

    private User find(Long id) {
        return users.findById(id).orElseThrow(() -> ApiException.notFound("Usuário não encontrado."));
    }

    public UserResponse create(UserCreateRequest r) {
        String email = r.email().trim().toLowerCase();
        if (users.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("Já existe um usuário com este e-mail.");
        }
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(r.password()));
        user.setRole(r.role());
        return UserResponse.from(users.save(user));
    }

    @Transactional(readOnly = true)
    public List<UserResponse> list() {
        return users.findAll().stream().map(UserResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public UserResponse get(Long id) {
        return UserResponse.from(find(id));
    }

    public UserResponse update(Long id, UserUpdateRequest r) {
        User user = find(id);
        if (r.email() != null && !r.email().isBlank()) {
            String email = r.email().trim().toLowerCase();
            if (!email.equalsIgnoreCase(user.getEmail()) && users.existsByEmailIgnoreCase(email)) {
                throw ApiException.conflict("Já existe um usuário com este e-mail.");
            }
            user.setEmail(email);
        }
        if (r.role() != null) user.setRole(r.role());
        if (r.active() != null) user.setActive(r.active());
        if (r.password() != null && !r.password().isBlank()) {
            user.setPasswordHash(encoder.encode(r.password()));
        }
        return UserResponse.from(user);
    }

    public void delete(Long id, Long currentUserId) {
        User user = find(id);
        if (user.getId().equals(currentUserId)) {
            throw ApiException.badRequest("Você não pode excluir a própria conta.");
        }
        if (donors.existsByUserId(id) || institutions.existsByUserId(id)) {
            throw ApiException.conflict(
                "O usuário possui cadastro vinculado. Exclua o cadastro antes ou suspenda a conta.");
        }
        users.delete(user);
    }

    public UserResponse me(Long id) {
        return UserResponse.from(find(id));
    }

    public void setFcmToken(Long id, String token) {
        find(id).setFcmToken(token.trim());
    }
}
