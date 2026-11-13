package br.edu.ifsp.doa.api.repository;

import br.edu.ifsp.doa.api.domain.Message;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MessageRepository extends JpaRepository<Message, Long> {
    List<Message> findByDonationIdOrderBySentAtAsc(Long donationId);
    void deleteByDonationId(Long donationId);
}
