package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.DonationPhoto;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DonationPhotoRepository extends JpaRepository<DonationPhoto, String> {
    /** Só os ids (sem carregar os bytes), na ordem de envio. */
    @Query("select p.id from DonationPhoto p where p.donation.id = :donationId order by p.createdAt, p.id")
    List<String> findIdsByDonationId(@Param("donationId") Long donationId);

    long countByDonationId(Long donationId);

    @Modifying
    @Query("delete from DonationPhoto p where p.donation.id = :donationId")
    void deleteByDonationId(@Param("donationId") Long donationId);
}
