package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.FoodCategory;
import br.edu.ifsp.doa.api.domain.Institution;
import br.edu.ifsp.doa.api.domain.InstitutionStatus;
import br.edu.ifsp.doa.api.domain.UserRole;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.FoodCategoryRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.repository.StockItemRepository;
import br.edu.ifsp.doa.api.repository.UserRepository;
import br.edu.ifsp.doa.api.util.DocumentValidator;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategorySummary;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionRequest;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionResponse;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionUpdateRequest;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class InstitutionService {
    private final InstitutionRepository institutions;
    private final UserRepository users;
    private final FoodCategoryRepository categories;
    private final DonationRepository donations;
    private final StockItemRepository stock;
    private final Notifier notifier;

    public InstitutionService(InstitutionRepository institutions, UserRepository users,
                              FoodCategoryRepository categories, DonationRepository donations,
                              StockItemRepository stock, Notifier notifier) {
        this.institutions = institutions;
        this.users = users;
        this.categories = categories;
        this.donations = donations;
        this.stock = stock;
        this.notifier = notifier;
    }

    private Institution mine(Long userId) {
        return institutions.findByUserId(userId)
            .orElseThrow(() -> ApiException.notFound("Cadastro da instituição não encontrado."));
    }

    private Institution byId(Long id) {
        return institutions.findById(id).orElseThrow(() -> ApiException.notFound("Instituição não encontrada."));
    }

    /** Toda categoria precisa existir e estar ativa. */
    private Set<FoodCategory> resolveCategories(List<Long> ids) {
        Set<FoodCategory> result = new HashSet<>();
        for (Long id : new HashSet<>(ids)) {
            FoodCategory c = categories.findById(id)
                .orElseThrow(() -> ApiException.badRequest("Categoria inválida."));
            if (!c.isActive()) {
                throw ApiException.badRequest("A categoria \"" + c.getName() + "\" está inativa.");
            }
            result.add(c);
        }
        if (result.isEmpty()) {
            throw ApiException.badRequest("Escolha ao menos uma categoria de alimento.");
        }
        return result;
    }

    public InstitutionResponse create(Long userId, InstitutionRequest r) {
        if (institutions.existsByUserId(userId)) {
            throw ApiException.conflict("O cadastro da instituição já foi enviado.");
        }
        String cnpj = DocumentValidator.digits(r.cnpj());
        if (!DocumentValidator.isValidCnpj(cnpj)) {
            throw ApiException.badRequest("CNPJ inválido.");
        }
        if (institutions.existsByCnpj(cnpj)) {
            throw ApiException.conflict("Este CNPJ já está cadastrado.");
        }
        Institution i = new Institution();
        i.setUser(users.getReferenceById(userId));
        i.setName(r.name().trim());
        i.setCnpj(cnpj);
        i.setAddress(r.address().trim());
        i.setCity(r.city().trim());
        i.setAreaOfActivity(r.areaOfActivity().trim());
        i.setStorageCapacityKg(r.storageCapacityKg());
        i.setLatitude(r.latitude());
        i.setLongitude(r.longitude());
        i.setStatus(InstitutionStatus.PENDING);
        i.setCategories(resolveCategories(r.categoryIds()));
        institutions.save(i);

        for (var admin : users.findByRole(UserRole.ADMIN)) {
            notifier.notify(admin, "Nova instituição aguardando aprovação", i.getName(),
                Map.of("event", "INSTITUTION_PENDING", "institutionId", i.getId()));
        }
        return InstitutionResponse.from(i);
    }

    @Transactional(readOnly = true)
    public InstitutionResponse getMine(Long userId) {
        return InstitutionResponse.from(mine(userId));
    }

    public InstitutionResponse updateMine(Long userId, InstitutionUpdateRequest r) {
        Institution i = mine(userId);
        i.setName(r.name().trim());
        i.setAddress(r.address().trim());
        i.setCity(r.city().trim());
        i.setAreaOfActivity(r.areaOfActivity().trim());
        i.setStorageCapacityKg(r.storageCapacityKg());
        i.setLatitude(r.latitude());
        i.setLongitude(r.longitude());
        if (i.getStatus() == InstitutionStatus.REJECTED) { // reenvio após correção
            i.setStatus(InstitutionStatus.PENDING);
            i.setRejectionReason(null);
        }
        return InstitutionResponse.from(i);
    }

    public void deleteMine(Long userId) {
        remove(mine(userId));
    }

    // ----- N:N com categorias -----

    @Transactional(readOnly = true)
    public List<CategorySummary> myCategories(Long userId) {
        return mine(userId).getCategories().stream()
            .map(CategorySummary::from)
            .sorted(Comparator.comparing(CategorySummary::name))
            .toList();
    }

    public InstitutionResponse replaceCategories(Long userId, List<Long> categoryIds) {
        Institution i = mine(userId);
        i.getCategories().clear();
        i.getCategories().addAll(resolveCategories(categoryIds));
        return InstitutionResponse.from(i);
    }

    public InstitutionResponse addCategory(Long userId, Long categoryId) {
        Institution i = mine(userId);
        i.getCategories().addAll(resolveCategories(List.of(categoryId)));
        return InstitutionResponse.from(i);
    }

    public InstitutionResponse removeCategory(Long userId, Long categoryId) {
        Institution i = mine(userId);
        FoodCategory target = i.getCategories().stream()
            .filter(c -> c.getId().equals(categoryId)).findFirst()
            .orElseThrow(() -> ApiException.notFound("A instituição não aceita esta categoria."));
        if (i.getCategories().size() == 1) {
            throw ApiException.badRequest("A instituição precisa aceitar ao menos uma categoria.");
        }
        i.getCategories().remove(target);
        return InstitutionResponse.from(i);
    }

    // ----- administrador -----

    @Transactional(readOnly = true)
    public List<InstitutionResponse> list(InstitutionStatus status) {
        var list = status == null ? institutions.findAll() : institutions.findByStatus(status);
        return list.stream().map(InstitutionResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public InstitutionResponse get(Long id) {
        return InstitutionResponse.from(byId(id));
    }

    public InstitutionResponse approve(Long id) {
        Institution i = pendingOrThrow(id);
        i.setStatus(InstitutionStatus.APPROVED);
        i.setRejectionReason(null);
        notifier.notify(i.getUser(), "Cadastro aprovado", "Sua instituição já pode buscar doações.",
            Map.of("event", "INSTITUTION_APPROVED"));
        return InstitutionResponse.from(i);
    }

    public InstitutionResponse reject(Long id, String reason) {
        Institution i = pendingOrThrow(id);
        i.setStatus(InstitutionStatus.REJECTED);
        i.setRejectionReason(reason.trim());
        notifier.notify(i.getUser(), "Cadastro rejeitado", reason.trim(),
            Map.of("event", "INSTITUTION_REJECTED"));
        return InstitutionResponse.from(i);
    }

    public void delete(Long id) {
        remove(byId(id));
    }

    private Institution pendingOrThrow(Long id) {
        Institution i = byId(id);
        if (i.getStatus() != InstitutionStatus.PENDING) {
            throw ApiException.conflict("Esta instituição já foi analisada.");
        }
        return i;
    }

    private void remove(Institution i) {
        if (donations.existsByReservedById(i.getId())) {
            throw ApiException.conflict("Há doações reservadas ou recebidas por esta instituição.");
        }
        stock.deleteByInstitutionId(i.getId());
        institutions.delete(i);
    }
}
