package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.Message;
import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.MessageRepository;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.MiscDtos.MessageResponse;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Chat (RF12) entre o doador e a instituição que reservou a doação. Entrega em tempo real via WebSocket. */
@Service
@Transactional
public class ChatService {
    private final DonationRepository donations;
    private final MessageRepository messages;
    private final Notifier notifier;

    public ChatService(DonationRepository donations, MessageRepository messages, Notifier notifier) {
        this.donations = donations;
        this.messages = messages;
        this.notifier = notifier;
    }

    private Donation participantDonation(AuthUser u, Long donationId) {
        Donation d = donations.findById(donationId)
            .orElseThrow(() -> ApiException.notFound("Doação não encontrada."));
        if (!isDonor(d, u) && !isReserver(d, u)) {
            throw ApiException.forbidden("Só o doador e a instituição que reservou participam desta conversa.");
        }
        return d;
    }

    private boolean isDonor(Donation d, AuthUser u) {
        return d.getDonor().getUser().getId().equals(u.id());
    }

    private boolean isReserver(Donation d, AuthUser u) {
        return d.getReservedBy() != null && d.getReservedBy().getUser().getId().equals(u.id());
    }

    private MessageResponse toResponse(Message m, Donation d) {
        boolean fromDonor = m.getSender().getId().equals(d.getDonor().getUser().getId());
        String name = fromDonor ? d.getDonor().getName()
            : (d.getReservedBy() == null ? "Instituição" : d.getReservedBy().getName());
        return new MessageResponse(m.getId(), d.getId(), m.getSender().getId(), name, m.getContent(), m.getSentAt());
    }

    @Transactional(readOnly = true)
    public List<MessageResponse> history(AuthUser u, Long donationId) {
        Donation d = participantDonation(u, donationId);
        return messages.findByDonationIdOrderBySentAtAsc(donationId).stream().map(m -> toResponse(m, d)).toList();
    }

    public MessageResponse send(AuthUser u, Long donationId, String content) {
        Donation d = participantDonation(u, donationId);
        if (d.getReservedBy() == null) {
            throw ApiException.conflict("O chat é liberado quando a doação é reservada.");
        }
        if (content == null || content.isBlank()) {
            throw ApiException.badRequest("Escreva a mensagem.");
        }
        if (content.length() > 1000) {
            throw ApiException.badRequest("A mensagem deve ter até 1000 caracteres.");
        }

        boolean fromDonor = isDonor(d, u);
        User sender = fromDonor ? d.getDonor().getUser() : d.getReservedBy().getUser();
        User recipient = fromDonor ? d.getReservedBy().getUser() : d.getDonor().getUser();

        Message m = new Message();
        m.setDonation(d);
        m.setSender(sender);
        m.setContent(content.trim());
        messages.save(m);

        MessageResponse response = toResponse(m, d);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", "chat");
        payload.put("id", response.id());
        payload.put("donationId", response.donationId());
        payload.put("senderUserId", response.senderUserId());
        payload.put("senderName", response.senderName());
        payload.put("content", response.content());
        payload.put("sentAt", response.sentAt().toString());

        notifier.websocketOnly(sender, payload);
        String preview = response.content().length() > 80 ? response.content().substring(0, 80) + "…" : response.content();
        notifier.websocketAndPush(recipient, payload, "Mensagem de " + response.senderName(), preview);
        return response;
    }
}
