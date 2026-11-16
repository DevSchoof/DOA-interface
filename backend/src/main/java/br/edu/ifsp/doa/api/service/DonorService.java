package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.Donor;
import br.edu.ifsp.doa.api.domain.PersonType;
import br.edu.ifsp.doa.api.domain.User;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.DonorRepository;
import br.edu.ifsp.doa.api.repository.UserRepository;
import br.edu.ifsp.doa.api.util.DocumentValidator;
import br.edu.ifsp.doa.api.web.ApiException;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorRequest;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorResponse;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorUpdateRequest;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class DonorService {
    private final DonorRepository donors;
    private final UserRepository users;
    private final DonationRepository donations;

    public DonorService(DonorRepository donors, UserRepository users, DonationRepository donations) {
        this.donors = donors;
        this.users = users;
        this.donations = donations;
    }

    private Donor mine(Long userId) {
        return donors.findByUserId(userId)
            .orElseThrow(() -> ApiException.notFound("Cadastro de doador não encontrado."));
    }

    private Donor byId(Long id) {
        return donors.findById(id).orElseThrow(() -> ApiException.notFound("Doador não encontrado."));
    }

    public DonorResponse create(Long userId, DonorRequest r) {
        if (donors.existsByUserId(userId)) {
            throw ApiException.conflict("Seu cadastro de doador já foi concluído.");
        }
        String document = DocumentValidator.digits(r.document());
        boolean company = r.personType() == PersonType.COMPANY;
        if (company ? !DocumentValidator.isValidCnpj(document) : !DocumentValidator.isValidCpf(document)) {
            throw ApiException.badRequest(company ? "CNPJ inválido." : "CPF inválido.");
        }
        String phone = DocumentValidator.digits(r.phone());
        if (phone.length() != 10 && phone.length() != 11) {
            throw ApiException.badRequest("Informe o telefone com DDD.");
        }
        if (donors.existsByDocument(document)) {
            throw ApiException.conflict("Este documento já está cadastrado.");
        }
        User user = users.getReferenceById(userId);
        Donor d = new Donor();
        d.setUser(user);
        d.setPersonType(r.personType());
        d.setName(r.name().trim());
        d.setDocument(document);
        d.setPhone(phone);
        d.setAddress(r.address().trim());
        d.setCity(r.city().trim());
        d.setLatitude(r.latitude());
        d.setLongitude(r.longitude());
        return DonorResponse.from(donors.save(d));
    }

    @Transactional(readOnly = true)
    public DonorResponse getMine(Long userId) {
        return DonorResponse.from(mine(userId));
    }

    public DonorResponse updateMine(Long userId, DonorUpdateRequest r) {
        return DonorResponse.from(apply(mine(userId), r));
    }

    public void deleteMine(Long userId) {
        remove(mine(userId));
    }

    // ----- administrador -----

    @Transactional(readOnly = true)
    public List<DonorResponse> list() {
        return donors.findAll().stream().map(DonorResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public DonorResponse get(Long id) {
        return DonorResponse.from(byId(id));
    }

    public DonorResponse update(Long id, DonorUpdateRequest r) {
        return DonorResponse.from(apply(byId(id), r));
    }

    public void delete(Long id) {
        remove(byId(id));
    }

    private Donor apply(Donor d, DonorUpdateRequest r) {
        String phone = DocumentValidator.digits(r.phone());
        if (phone.length() != 10 && phone.length() != 11) {
            throw ApiException.badRequest("Informe o telefone com DDD.");
        }
        d.setName(r.name().trim());
        d.setPhone(phone);
        d.setAddress(r.address().trim());
        d.setCity(r.city().trim());
        d.setLatitude(r.latitude());
        d.setLongitude(r.longitude());
        return d;
    }

    private void remove(Donor d) {
        if (donations.existsByDonorId(d.getId())) {
            throw ApiException.conflict("Há doações vinculadas a este doador. Cancele ou exclua as doações antes.");
        }
        donors.delete(d);
    }
}
