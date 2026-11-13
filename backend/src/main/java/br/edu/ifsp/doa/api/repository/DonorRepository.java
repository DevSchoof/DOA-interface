package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.Donor;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DonorRepository extends JpaRepository<Donor, Long> {
    Optional<Donor> findByUserId(Long userId);
    boolean existsByUserId(Long userId);
    boolean existsByDocument(String document);
}
