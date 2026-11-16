package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.FoodCategory;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, Long> {
    boolean existsByNameIgnoreCase(String name);
    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);
    List<FoodCategory> findByActiveTrueOrderByNameAsc();
    List<FoodCategory> findAllByOrderByNameAsc();
}
