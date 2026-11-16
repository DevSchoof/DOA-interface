package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.DonationStatus;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DonationRepository extends JpaRepository<Donation, Long> {
    List<Donation> findByDonorIdOrderByCreatedAtDesc(Long donorId);
    List<Donation> findByReservedByIdOrderByReservedAtDesc(Long institutionId);
    List<Donation> findByStatusAndExpiresAtGreaterThanEqualAndCategoryIdIn(
        DonationStatus status, LocalDate today, Collection<Long> categoryIds);
    long countByReservedByIdAndStatus(Long institutionId, DonationStatus status);
    List<Donation> findByStatusAndReservedAtBefore(DonationStatus status, LocalDateTime limit);
    List<Donation> findByStatusAndExpiresAtBefore(DonationStatus status, LocalDate today);
    boolean existsByDonorId(Long donorId);
    boolean existsByCategoryId(Long categoryId);
    boolean existsByReservedById(Long institutionId);
}
