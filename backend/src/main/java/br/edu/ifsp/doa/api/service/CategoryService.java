package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.FoodCategory;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.FoodCategoryRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.repository.StockItemRepository;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategoryRequest;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategoryResponse;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class CategoryService {
    private final FoodCategoryRepository categories;
    private final DonationRepository donations;
    private final InstitutionRepository institutions;
    private final StockItemRepository stock;

    public CategoryService(FoodCategoryRepository categories, DonationRepository donations,
                           InstitutionRepository institutions, StockItemRepository stock) {
        this.categories = categories;
        this.donations = donations;
        this.institutions = institutions;
        this.stock = stock;
    }

    private FoodCategory find(Long id) {
        return categories.findById(id).orElseThrow(() -> ApiException.notFound("Categoria não encontrada."));
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(boolean includeInactive) {
        var list = includeInactive ? categories.findAllByOrderByNameAsc() : categories.findByActiveTrueOrderByNameAsc();
        return list.stream().map(CategoryResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public CategoryResponse get(Long id) {
        return CategoryResponse.from(find(id));
    }

    public CategoryResponse create(CategoryRequest r) {
        String name = r.name().trim();
        if (categories.existsByNameIgnoreCase(name)) {
            throw ApiException.conflict("Já existe uma categoria com este nome.");
        }
        FoodCategory c = new FoodCategory(name, r.description());
        if (r.active() != null) c.setActive(r.active());
        return CategoryResponse.from(categories.save(c));
    }

    public CategoryResponse update(Long id, CategoryRequest r) {
        FoodCategory c = find(id);
        String name = r.name().trim();
        if (categories.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw ApiException.conflict("Já existe uma categoria com este nome.");
        }
        c.setName(name);
        c.setDescription(r.description());
        if (r.active() != null) c.setActive(r.active());
        return CategoryResponse.from(c);
    }

    public void delete(Long id) {
        FoodCategory c = find(id);
        if (donations.existsByCategoryId(id) || institutions.existsByCategoriesId(id) || stock.existsByCategoryId(id)) {
            throw ApiException.conflict("Categoria em uso. Desative-a em vez de excluir.");
        }
        categories.delete(c);
    }
}
