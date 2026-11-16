package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.config.AppProperties;
import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.DonationStatus;
import br.edu.ifsp.doa.api.domain.Donor;
import br.edu.ifsp.doa.api.domain.FoodCategory;
import br.edu.ifsp.doa.api.domain.Institution;
import br.edu.ifsp.doa.api.domain.InstitutionStatus;
import br.edu.ifsp.doa.api.domain.StockItem;
import br.edu.ifsp.doa.api.domain.UserRole;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.DonorRepository;
import br.edu.ifsp.doa.api.repository.FoodCategoryRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.repository.MessageRepository;
import br.edu.ifsp.doa.api.repository.StockItemRepository;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.util.GeoUtils;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.DonationDtos.DonationRequest;
import br.edu.ifsp.doa.api.web.dto.DonationDtos.DonationResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class DonationService {
    private static final Logger log = LoggerFactory.getLogger(DonationService.class);
    private static final int MAX_ACTIVE_REQUESTS = 5;

    private final DonationRepository donations;
    private final DonorRepository donors;
    private final InstitutionRepository institutions;
    private final FoodCategoryRepository categories;
    private final StockItemRepository stock;
    private final MessageRepository messages;
    private final PhotoService photoService;
    private final Notifier notifier;
    private final AppProperties props;

    public DonationService(DonationRepository donations, DonorRepository donors,
                           InstitutionRepository institutions, FoodCategoryRepository categories,
                           StockItemRepository stock, MessageRepository messages,
                           PhotoService photoService, Notifier notifier, AppProperties props) {
        this.donations = donations;
        this.donors = donors;
        this.institutions = institutions;
        this.categories = categories;
        this.stock = stock;
        this.messages = messages;
        this.photoService = photoService;
        this.notifier = notifier;
        this.props = props;
    }

    // ---------- helpers ----------

    private Donation find(Long id) {
        return donations.findById(id).orElseThrow(() -> ApiException.notFound("Doação não encontrada."));
    }

    private Donor donorOf(AuthUser u) {
        return donors.findByUserId(u.id())
            .orElseThrow(() -> ApiException.badRequest("Complete seu cadastro de doador antes de doar."));
    }

    private Institution institutionOf(AuthUser u, boolean approvedOnly) {
        Institution i = institutions.findByUserId(u.id())
            .orElseThrow(() -> ApiException.forbidden("Complete o cadastro da instituição."));
        if (approvedOnly && i.getStatus() != InstitutionStatus.APPROVED) {
            throw ApiException.forbidden("Seu cadastro ainda aguarda aprovação.");
        }
        return i;
    }

    private DonationResponse toResponse(Donation d, Double distanceKm) {
        return DonationResponse.from(d, distanceKm, photoService.urlsOf(d.getId()));
    }

    private Donation ownedBy(AuthUser u, Long id) {
        Donation d = find(id);
        if (!d.getDonor().getUser().getId().equals(u.id())) {
            throw ApiException.forbidden("Você não tem permissão para esta ação.");
        }
        return d;
    }

    private FoodCategory activeCategory(Long id) {
        FoodCategory c = categories.findById(id).orElseThrow(() -> ApiException.badRequest("Categoria inválida."));
        if (!c.isActive()) throw ApiException.badRequest("Esta categoria está inativa.");
        return c;
    }

    private void apply(Donation d, DonationRequest r) {
        Rules.requireUnit(r.unit());
        Rules.requireNotExpired(r.expiresAt());
        d.setCategory(activeCategory(r.categoryId()));
        d.setDescription(r.description().trim());
        d.setQuantity(r.quantity());
        d.setUnit(r.unit());
        d.setExpiresAt(r.expiresAt());
        d.setStorageConditions(r.storageConditions());
    }

    private Double distanceFrom(Institution i, Donation d) {
        return i == null ? null
            : GeoUtils.distanceKm(i.getLatitude(), i.getLongitude(), d.getDonor().getLatitude(), d.getDonor().getLongitude());
    }

    // ---------- doador ----------

    public DonationResponse create(AuthUser u, DonationRequest r) {
        Donor donor = donorOf(u);
        Donation d = new Donation();
        d.setDonor(donor);
        apply(d, r);
        donations.save(d);
        notifyInstitutions(d);
        return toResponse(d, null);
    }

    /** Regra N:N: só avisa instituições aprovadas que aceitam a categoria e estão dentro do raio. */
    private void notifyInstitutions(Donation d) {
        for (Institution i : institutions.findByStatusAndCategoriesId(InstitutionStatus.APPROVED, d.getCategory().getId())) {
            Double km = distanceFrom(i, d);
            if (km != null && km > props.defaultRadiusKm()) continue;
            notifier.notify(i.getUser(), "Nova doação disponível",
                d.getCategory().getName() + ": " + d.getDescription(),
                Map.of("event", "NEW_DONATION", "donationId", d.getId()));
        }
    }

    @Transactional(readOnly = true)
    public List<DonationResponse> listMine(AuthUser u) {
        Donor donor = donorOf(u);
        return donations.findByDonorIdOrderByCreatedAtDesc(donor.getId()).stream()
            .map(d -> toResponse(d, null)).toList();
    }

    public DonationResponse update(AuthUser u, Long id, DonationRequest r) {
        Donation d = ownedBy(u, id);
        if (d.getStatus() != DonationStatus.AVAILABLE) {
            throw ApiException.conflict("Só é possível editar doações disponíveis.");
        }
        apply(d, r);
        return toResponse(d, null);
    }

    public void delete(AuthUser u, Long id) {
        Donation d = ownedBy(u, id);
        Set<DonationStatus> deletable = Set.of(DonationStatus.AVAILABLE, DonationStatus.CANCELLED, DonationStatus.EXPIRED);
        if (!deletable.contains(d.getStatus())) {
            throw ApiException.conflict("Doações reservadas ou entregues não podem ser excluídas.");
        }
        messages.deleteByDonationId(id);
        photoService.removeAllOf(id);
        donations.delete(d);
    }

    public DonationResponse cancel(AuthUser u, Long id) {
        Donation d = ownedBy(u, id);
        if (d.getStatus() != DonationStatus.AVAILABLE && d.getStatus() != DonationStatus.RESERVED) {
            throw ApiException.conflict("Esta doação não pode mais ser cancelada.");
        }
        if (d.getStatus() == DonationStatus.RESERVED && d.getReservedBy() != null) {
            notifier.notify(d.getReservedBy().getUser(), "Doação cancelada",
                "O doador cancelou: " + d.getDescription(),
                Map.of("event", "DONATION_CANCELLED", "donationId", d.getId()));
        }
        d.setStatus(DonationStatus.CANCELLED);
        return toResponse(d, null);
    }

    // ---------- instituição ----------

    /**
     * Busca (CSU04): só doações disponíveis, não vencidas, de categorias que a instituição aceita (N:N),
     * dentro do raio e ordenadas por proximidade. Sem coordenadas a distância fica nula e o raio não se aplica.
     */
    @Transactional(readOnly = true)
    public List<DonationResponse> search(AuthUser u, Long categoryId, Double radiusKm, Double lat, Double lng) {
        Institution inst = institutionOf(u, true);
        Set<Long> accepted = inst.getCategories().stream().map(FoodCategory::getId).collect(Collectors.toSet());
        if (categoryId != null) {
            accepted = accepted.contains(categoryId) ? Set.of(categoryId) : Set.of();
        }
        if (accepted.isEmpty()) return List.of();

        Double originLat = lat != null ? lat : inst.getLatitude();
        Double originLng = lng != null ? lng : inst.getLongitude();
        double radius = radiusKm != null ? radiusKm : props.defaultRadiusKm();

        return donations
            .findByStatusAndExpiresAtGreaterThanEqualAndCategoryIdIn(DonationStatus.AVAILABLE, LocalDate.now(), accepted)
            .stream()
            .map(d -> toResponse(d, GeoUtils.distanceKm(originLat, originLng,
                d.getDonor().getLatitude(), d.getDonor().getLongitude())))
            .filter(r -> r.distanceKm() == null || r.distanceKm() <= radius)
            .sorted(Comparator
                .comparing(DonationResponse::distanceKm, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(DonationResponse::expiresAt))
            .toList();
    }

    @Transactional(readOnly = true)
    public List<DonationResponse> listRequested(AuthUser u) {
        Institution inst = institutionOf(u, false);
        return donations.findByReservedByIdOrderByReservedAtDesc(inst.getId()).stream()
            .map(d -> toResponse(d, distanceFrom(inst, d))).toList();
    }

    @Transactional(readOnly = true)
    public DonationResponse get(AuthUser u, Long id) {
        Donation d = find(id);
        Double distance = null;
        if (u.role() == UserRole.DONOR && !d.getDonor().getUser().getId().equals(u.id())) {
            throw ApiException.forbidden("Você não tem permissão para esta ação.");
        }
        if (u.role() == UserRole.INSTITUTION) {
            distance = distanceFrom(institutions.findByUserId(u.id()).orElse(null), d);
        }
        return toResponse(d, distance);
    }

    public DonationResponse request(AuthUser u, Long id) {
        Institution inst = institutionOf(u, true);
        Donation d = find(id);

        if (d.getStatus() != DonationStatus.AVAILABLE || d.getExpiresAt().isBefore(LocalDate.now())) {
            throw ApiException.conflict("Esta doação não está mais disponível.");
        }
        boolean accepts = inst.getCategories().stream().anyMatch(c -> c.getId().equals(d.getCategory().getId()));
        if (!accepts) {
            throw ApiException.conflict("Sua instituição não aceita a categoria \"" + d.getCategory().getName() + "\".");
        }
        if (donations.countByReservedByIdAndStatus(inst.getId(), DonationStatus.RESERVED) >= MAX_ACTIVE_REQUESTS) {
            throw ApiException.conflict("Limite de " + MAX_ACTIVE_REQUESTS + " solicitações ativas atingido.");
        }

        d.setStatus(DonationStatus.RESERVED);
        d.setReservedBy(inst);
        d.setReservedAt(LocalDateTime.now());
        notifier.notify(d.getDonor().getUser(), "Doação reservada",
            inst.getName() + " reservou: " + d.getDescription(),
            Map.of("event", "DONATION_RESERVED", "donationId", d.getId()));
        return toResponse(d, distanceFrom(inst, d));
    }

    public DonationResponse confirmDelivery(AuthUser u, Long id) {
        Institution inst = institutionOf(u, true);
        Donation d = find(id);
        if (d.getStatus() != DonationStatus.RESERVED
                || d.getReservedBy() == null || !d.getReservedBy().getId().equals(inst.getId())) {
            throw ApiException.conflict("Esta doação não está reservada para você.");
        }

        StockItem item = new StockItem();
        item.setInstitution(inst);
        item.setCategory(d.getCategory());
        item.setDescription(d.getDescription());
        item.setQuantity(d.getQuantity());
        item.setUnit(d.getUnit());
        item.setExpiresAt(d.getExpiresAt());
        stock.save(item);

        d.setStatus(DonationStatus.DELIVERED);
        notifier.notify(d.getDonor().getUser(), "Doação entregue",
            inst.getName() + " confirmou o recebimento de: " + d.getDescription(),
            Map.of("event", "DONATION_DELIVERED", "donationId", d.getId()));
        return toResponse(d, distanceFrom(inst, d));
    }

    // ---------- rotina agendada ----------

    /** Libera reservas não coletadas no prazo e marca como expiradas as doações vencidas. */
    @Scheduled(fixedDelayString = "PT5M", initialDelayString = "PT1M")
    public void maintenance() {
        LocalDateTime limit = LocalDateTime.now().minusHours(props.reservationHours());
        for (Donation d : donations.findByStatusAndReservedAtBefore(DonationStatus.RESERVED, limit)) {
            Institution previous = d.getReservedBy();
            d.setStatus(DonationStatus.AVAILABLE);
            d.setReservedBy(null);
            d.setReservedAt(null);
            if (previous != null) {
                notifier.notify(previous.getUser(), "Reserva liberada",
                    "O prazo de coleta terminou: " + d.getDescription(),
                    Map.of("event", "RESERVATION_RELEASED", "donationId", d.getId()));
            }
            log.info("Reserva da doação {} liberada por atraso na coleta.", d.getId());
        }
        for (Donation d : donations.findByStatusAndExpiresAtBefore(DonationStatus.AVAILABLE, LocalDate.now())) {
            d.setStatus(DonationStatus.EXPIRED);
            log.info("Doação {} marcada como expirada.", d.getId());
        }
    }
}
