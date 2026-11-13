package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.domain.UserRole;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmailIgnoreCase(String email);
    boolean existsByEmailIgnoreCase(String email);
    boolean existsByRole(UserRole role);
    List<User> findByRole(UserRole role);
}
