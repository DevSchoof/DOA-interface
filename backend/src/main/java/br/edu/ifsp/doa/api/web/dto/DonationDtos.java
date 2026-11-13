package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.DonationStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class DonationDtos {
    private DonationDtos() {}

    public record DonationRequest(
        @NotNull(message = "Escolha a categoria do alimento.") Long categoryId,
        @NotBlank(message = "Descreva o alimento.")
        @Size(max = 120, message = "A descrição deve ter até 120 caracteres.") String description,
        @NotNull(message = "Informe a quantidade.")
        @Positive(message = "Informe uma quantidade maior que zero.") Double quantity,
        @NotBlank(message = "Informe a unidade (kg, un ou L).") String unit,
        @NotNull(message = "Informe a validade.") LocalDate expiresAt,
        String storageConditions) {}

    public record DonationResponse(
        Long id, Long donorId, String donorName, Long categoryId, String categoryName,
        String description, double quantity, String unit, LocalDate expiresAt,
        String storageConditions, DonationStatus status, Long reservedById, String reservedByName,
        LocalDateTime reservedAt, LocalDateTime createdAt, String city, Double distanceKm,
        List<String> photoUrls) {

        public static DonationResponse from(Donation d, Double distanceKm, List<String> photoUrls) {
            var by = d.getReservedBy();
            return new DonationResponse(
                d.getId(), d.getDonor().getId(), d.getDonor().getName(),
                d.getCategory().getId(), d.getCategory().getName(),
                d.getDescription(), d.getQuantity(), d.getUnit(), d.getExpiresAt(),
                d.getStorageConditions(), d.getStatus(),
                by == null ? null : by.getId(), by == null ? null : by.getName(),
                d.getReservedAt(), d.getCreatedAt(), d.getDonor().getCity(), distanceKm, photoUrls);
        }
    }
}
