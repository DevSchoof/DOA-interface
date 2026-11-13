package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.StockItem;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockItemRepository extends JpaRepository<StockItem, Long> {
    List<StockItem> findByInstitutionIdOrderByExpiresAtAsc(Long institutionId);
    boolean existsByCategoryId(Long categoryId);
    void deleteByInstitutionId(Long institutionId);
}
