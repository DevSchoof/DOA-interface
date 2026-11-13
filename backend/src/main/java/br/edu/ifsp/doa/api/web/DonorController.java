package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.DonorService;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorRequest;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorResponse;
import br.edu.ifsp.doa.api.web.dto.DonorDtos.DonorUpdateRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/donors")
public class DonorController {
    private final DonorService donors;

    public DonorController(DonorService donors) {
        this.donors = donors;
    }

    // ----- o próprio doador -----

    @PostMapping
    @PreAuthorize("hasRole('DONOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public DonorResponse create(@AuthenticationPrincipal AuthUser user, @Valid @RequestBody DonorRequest request) {
        return donors.create(user.id(), request);
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('DONOR')")
    public DonorResponse me(@AuthenticationPrincipal AuthUser user) {
        return donors.getMine(user.id());
    }

    @PutMapping("/me")
    @PreAuthorize("hasRole('DONOR')")
    public DonorResponse updateMe(@AuthenticationPrincipal AuthUser user,
                                  @Valid @RequestBody DonorUpdateRequest request) {
        return donors.updateMine(user.id(), request);
    }

    @DeleteMapping("/me")
    @PreAuthorize("hasRole('DONOR')")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal AuthUser user) {
        donors.deleteMine(user.id());
        return ResponseEntity.noContent().build();
    }

    // ----- administrador -----

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<DonorResponse> list() {
        return donors.list();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public DonorResponse get(@PathVariable Long id) {
        return donors.get(id);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public DonorResponse update(@PathVariable Long id, @Valid @RequestBody DonorUpdateRequest request) {
        return donors.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        donors.delete(id);
        return ResponseEntity.noContent().build();
    }
}
