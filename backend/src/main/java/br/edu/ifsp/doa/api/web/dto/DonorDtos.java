package br.edu.ifsp.doa.api.web.dto;

import br.edu.ifsp.doa.api.domain.Donor;
import br.edu.ifsp.doa.api.domain.PersonType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public final class DonorDtos {
    private DonorDtos() {}

    public record DonorRequest(
        @NotNull(message = "Selecione pessoa física ou jurídica.") PersonType personType,
        @NotBlank(message = "Informe o nome.") String name,
        @NotBlank(message = "Informe o documento.") String document,
        @NotBlank(message = "Informe o telefone.") String phone,
        @NotBlank(message = "Informe o endereço.") String address,
        @NotBlank(message = "Informe a cidade.") String city,
        Double latitude,
        Double longitude) {}

    /** Documento e tipo de pessoa não mudam depois do cadastro. */
    public record DonorUpdateRequest(
        @NotBlank(message = "Informe o nome.") String name,
        @NotBlank(message = "Informe o telefone.") String phone,
        @NotBlank(message = "Informe o endereço.") String address,
        @NotBlank(message = "Informe a cidade.") String city,
        Double latitude,
        Double longitude) {}

    public record DonorResponse(
        Long id, Long userId, PersonType personType, String name, String document,
        String phone, String address, String city, Double latitude, Double longitude) {
        public static DonorResponse from(Donor d) {
            return new DonorResponse(d.getId(), d.getUser().getId(), d.getPersonType(), d.getName(),
                d.getDocument(), d.getPhone(), d.getAddress(), d.getCity(), d.getLatitude(), d.getLongitude());
        }
    }
}
