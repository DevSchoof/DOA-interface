package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.Institution;
import br.edu.ifsp.doa.api.domain.InstitutionStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InstitutionRepository extends JpaRepository<Institution, Long> {
    Optional<Institution> findByUserId(Long userId);
    boolean existsByUserId(Long userId);
    boolean existsByCnpj(String cnpj);
    boolean existsByCategoriesId(Long categoryId);
    List<Institution> findByStatus(InstitutionStatus status);
    List<Institution> findByStatusAndCategoriesId(InstitutionStatus status, Long categoryId);
}
