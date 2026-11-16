package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.StockItem;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.time.LocalDate;
import java.time.LocalDateTime;

public final class StockDtos {
    private StockDtos() {}

    public record StockRequest(
        @NotNull(message = "Escolha a categoria.") Long categoryId,
        @NotBlank(message = "Descreva o item.") String description,
        @NotNull(message = "Informe a quantidade.")
        @Positive(message = "Informe uma quantidade maior que zero.") Double quantity,
        @NotBlank(message = "Informe a unidade (kg, un ou L).") String unit,
        @NotNull(message = "Informe a validade.") LocalDate expiresAt) {}

    public record StockResponse(
        Long id, Long categoryId, String categoryName, String description, double quantity,
        String unit, LocalDateTime receivedAt, LocalDate expiresAt) {
        public static StockResponse from(StockItem s) {
            return new StockResponse(s.getId(), s.getCategory().getId(), s.getCategory().getName(),
                s.getDescription(), s.getQuantity(), s.getUnit(), s.getReceivedAt(), s.getExpiresAt());
        }
    }
}
