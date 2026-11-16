package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.domain.InstitutionStatus;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.InstitutionService;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategorySummary;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.CategoryIdsRequest;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionRequest;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionResponse;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.InstitutionUpdateRequest;
import br.edu.ifsp.doa.api.web.dto.InstitutionDtos.RejectRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/institutions")
public class InstitutionController {
    private final InstitutionService institutions;

    public InstitutionController(InstitutionService institutions) {
        this.institutions = institutions;
    }

    // ----- a própria instituição -----

    @PostMapping
    @PreAuthorize("hasRole('INSTITUTION')")
    @ResponseStatus(HttpStatus.CREATED)
    public InstitutionResponse create(@AuthenticationPrincipal AuthUser user,
                                      @Valid @RequestBody InstitutionRequest request) {
        return institutions.create(user.id(), request);
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('INSTITUTION')")
    public InstitutionResponse me(@AuthenticationPrincipal AuthUser user) {
        return institutions.getMine(user.id());
    }

    @PutMapping("/me")
    @PreAuthorize("hasRole('INSTITUTION')")
    public InstitutionResponse updateMe(@AuthenticationPrincipal AuthUser user,
                                        @Valid @RequestBody InstitutionUpdateRequest request) {
        return institutions.updateMine(user.id(), request);
    }

    @DeleteMapping("/me")
    @PreAuthorize("hasRole('INSTITUTION')")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal AuthUser user) {
        institutions.deleteMine(user.id());
        return ResponseEntity.noContent().build();
    }

    // ----- N:N: categorias que a instituição aceita -----

    @GetMapping("/me/categories")
    @PreAuthorize("hasRole('INSTITUTION')")
    public List<CategorySummary> myCategories(@AuthenticationPrincipal AuthUser user) {
        return institutions.myCategories(user.id());
    }

    @PutMapping("/me/categories")
    @PreAuthorize("hasRole('INSTITUTION')")
    public InstitutionResponse replaceCategories(@AuthenticationPrincipal AuthUser user,
                                                 @Valid @RequestBody CategoryIdsRequest request) {
        return institutions.replaceCategories(user.id(), request.categoryIds());
    }

    @PostMapping("/me/categories/{categoryId}")
    @PreAuthorize("hasRole('INSTITUTION')")
    public InstitutionResponse addCategory(@AuthenticationPrincipal AuthUser user, @PathVariable Long categoryId) {
        return institutions.addCategory(user.id(), categoryId);
    }

    @DeleteMapping("/me/categories/{categoryId}")
    @PreAuthorize("hasRole('INSTITUTION')")
    public InstitutionResponse removeCategory(@AuthenticationPrincipal AuthUser user, @PathVariable Long categoryId) {
        return institutions.removeCategory(user.id(), categoryId);
    }

    // ----- administrador -----

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<InstitutionResponse> list(@RequestParam(required = false) InstitutionStatus status) {
        return institutions.list(status);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public InstitutionResponse get(@PathVariable Long id) {
        return institutions.get(id);
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public InstitutionResponse approve(@PathVariable Long id) {
        return institutions.approve(id);
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public InstitutionResponse reject(@PathVariable Long id, @Valid @RequestBody RejectRequest request) {
        return institutions.reject(id, request.reason());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        institutions.delete(id);
        return ResponseEntity.noContent().build();
    }
}
