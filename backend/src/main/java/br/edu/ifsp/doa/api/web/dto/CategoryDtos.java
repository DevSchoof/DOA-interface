package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.FoodCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class CategoryDtos {
    private CategoryDtos() {}

    public record CategoryRequest(
        @NotBlank(message = "Informe o nome da categoria.")
        @Size(max = 60, message = "O nome deve ter até 60 caracteres.") String name,
        @Size(max = 200, message = "A descrição deve ter até 200 caracteres.") String description,
        Boolean active) {}

    public record CategoryResponse(Long id, String name, String description, boolean active) {
        public static CategoryResponse from(FoodCategory c) {
            return new CategoryResponse(c.getId(), c.getName(), c.getDescription(), c.isActive());
        }
    }

    public record CategorySummary(Long id, String name) {
        public static CategorySummary from(FoodCategory c) {
            return new CategorySummary(c.getId(), c.getName());
        }
    }
}
