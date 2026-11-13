package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.Institution;
import br.edu.ifsp.doa.api.domain.InstitutionStatus;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategorySummary;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.util.Comparator;
import java.util.List;

public final class InstitutionDtos {
    private InstitutionDtos() {}

    public record InstitutionRequest(
        @NotBlank(message = "Informe o nome da instituição.") String name,
        @NotBlank(message = "Informe o CNPJ.") String cnpj,
        @NotBlank(message = "Informe o endereço.") String address,
        @NotBlank(message = "Informe a cidade.") String city,
        @NotBlank(message = "Informe a área de atuação.") String areaOfActivity,
        @NotNull(message = "Informe a capacidade de armazenamento.")
        @Positive(message = "A capacidade deve ser maior que zero.") Double storageCapacityKg,
        @NotEmpty(message = "Escolha ao menos uma categoria de alimento.") List<Long> categoryIds,
        Double latitude,
        Double longitude) {}

    public record InstitutionUpdateRequest(
        @NotBlank(message = "Informe o nome da instituição.") String name,
        @NotBlank(message = "Informe o endereço.") String address,
        @NotBlank(message = "Informe a cidade.") String city,
        @NotBlank(message = "Informe a área de atuação.") String areaOfActivity,
        @NotNull(message = "Informe a capacidade de armazenamento.")
        @Positive(message = "A capacidade deve ser maior que zero.") Double storageCapacityKg,
        Double latitude,
        Double longitude) {}

    public record CategoryIdsRequest(
        @NotEmpty(message = "Escolha ao menos uma categoria de alimento.") List<Long> categoryIds) {}

    public record RejectRequest(@NotBlank(message = "Informe a justificativa da rejeição.") String reason) {}

    public record InstitutionResponse(
        Long id, Long userId, String name, String cnpj, String address, String city,
        String areaOfActivity, double storageCapacityKg, InstitutionStatus status,
        String rejectionReason, Double latitude, Double longitude, List<CategorySummary> categories) {
        public static InstitutionResponse from(Institution i) {
            return new InstitutionResponse(i.getId(), i.getUser().getId(), i.getName(), i.getCnpj(),
                i.getAddress(), i.getCity(), i.getAreaOfActivity(), i.getStorageCapacityKg(), i.getStatus(),
                i.getRejectionReason(), i.getLatitude(), i.getLongitude(),
                i.getCategories().stream()
                    .map(CategorySummary::from)
                    .sorted(Comparator.comparing(CategorySummary::name))
                    .toList());
        }
    }
}
