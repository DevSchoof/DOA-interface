package br.edu.ifsp.doa.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public final class MiscDtos {
    private MiscDtos() {}

    public record ImpactResponse(
        int donationsCount, int deliveredCount, double wasteAvoidedKg, long peopleServed, int institutionsServed) {}

    public record MessageRequest(
        @NotBlank(message = "Escreva a mensagem.")
        @Size(max = 1000, message = "A mensagem deve ter até 1000 caracteres.") String content) {}

    public record MessageResponse(
        Long id, Long donationId, Long senderUserId, String senderName, String content, LocalDateTime sentAt) {}
}
