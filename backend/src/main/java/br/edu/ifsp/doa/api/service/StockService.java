package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.FoodCategory;
import br.edu.ifsp.doa.api.domain.Institution;
import br.edu.ifsp.doa.api.domain.StockItem;
import br.edu.ifsp.doa.api.repository.FoodCategoryRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.repository.StockItemRepository;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.StockDtos.StockRequest;
import br.edu.ifsp.doa.api.web.dto.StockDtos.StockResponse;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class StockService {
    private final StockItemRepository stock;
    private final InstitutionRepository institutions;
    private final FoodCategoryRepository categories;

    public StockService(StockItemRepository stock, InstitutionRepository institutions,
                        FoodCategoryRepository categories) {
        this.stock = stock;
        this.institutions = institutions;
        this.categories = categories;
    }

    private Institution institution(Long userId) {
        return institutions.findByUserId(userId)
            .orElseThrow(() -> ApiException.forbidden("Complete o cadastro da instituição."));
    }

    private StockItem owned(Long userId, Long id) {
        Institution inst = institution(userId);
        StockItem item = stock.findById(id).orElseThrow(() -> ApiException.notFound("Item não encontrado."));
        if (!item.getInstitution().getId().equals(inst.getId())) {
            throw ApiException.notFound("Item não encontrado.");
        }
        return item;
    }

    private void apply(StockItem item, StockRequest r) {
        Rules.requireUnit(r.unit());
        FoodCategory c = categories.findById(r.categoryId())
            .orElseThrow(() -> ApiException.badRequest("Categoria inválida."));
        item.setCategory(c);
        item.setDescription(r.description().trim());
        item.setQuantity(r.quantity());
        item.setUnit(r.unit());
        item.setExpiresAt(r.expiresAt());
    }

    @Transactional(readOnly = true)
    public List<StockResponse> list(Long userId) {
        return stock.findByInstitutionIdOrderByExpiresAtAsc(institution(userId).getId())
            .stream().map(StockResponse::from).toList();
    }

    public StockResponse create(Long userId, StockRequest r) {
        Rules.requireNotExpired(r.expiresAt());
        StockItem item = new StockItem();
        item.setInstitution(institution(userId));
        apply(item, r);
        return StockResponse.from(stock.save(item));
    }

    public StockResponse update(Long userId, Long id, StockRequest r) {
        StockItem item = owned(userId, id);
        apply(item, r);
        return StockResponse.from(item);
    }

    public void delete(Long userId, Long id) {
        stock.delete(owned(userId, id));
    }
}
