package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.DonationStatus;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.DonorRepository;
import br.edu.ifsp.doa.api.repository.InstitutionRepository;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.web.dto.MiscDtos.ImpactResponse;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ImpactService {
    /** 1 refeição ≈ 500 g de alimento. */
    private static final double KG_PER_PERSON = 0.5;

    private final DonationRepository donations;
    private final DonorRepository donors;
    private final InstitutionRepository institutions;

    public ImpactService(DonationRepository donations, DonorRepository donors, InstitutionRepository institutions) {
        this.donations = donations;
        this.donors = donors;
        this.institutions = institutions;
    }

    public ImpactResponse summary(AuthUser u) {
        List<Donation> scope = switch (u.role()) {
            case DONOR -> donors.findByUserId(u.id())
                .map(d -> donations.findByDonorIdOrderByCreatedAtDesc(d.getId())).orElse(List.of());
            case INSTITUTION -> institutions.findByUserId(u.id())
                .map(i -> donations.findByReservedByIdOrderByReservedAtDesc(i.getId())).orElse(List.of());
            default -> donations.findAll();
        };

        List<Donation> delivered = scope.stream().filter(d -> d.getStatus() == DonationStatus.DELIVERED).toList();
        double kg = delivered.stream().filter(d -> "kg".equals(d.getUnit())).mapToDouble(Donation::getQuantity).sum();
        int institutionsServed = (int) delivered.stream()
            .map(d -> d.getReservedBy() == null ? null : d.getReservedBy().getId())
            .filter(Objects::nonNull).distinct().count();

        return new ImpactResponse(scope.size(), delivered.size(), kg, Math.round(kg / KG_PER_PERSON), institutionsServed);
    }
}
