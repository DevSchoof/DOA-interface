package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.domain.UserRole;
import br.edu.ifsp.doa.api.service.CategoryService;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategoryRequest;
import br.edu.ifsp.doa.api.web.dto.CategoryDtos.CategoryResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/categories")
public class CategoryController {
    private final CategoryService categories;

    public CategoryController(CategoryService categories) {
        this.categories = categories;
    }

    /** Qualquer usuário logado lista as categorias ativas. O admin pode pedir também as inativas. */
    @GetMapping
    public List<CategoryResponse> list(@AuthenticationPrincipal AuthUser user,
                                       @RequestParam(defaultValue = "false") boolean includeInactive) {
        return categories.list(includeInactive && user.role() == UserRole.ADMIN);
    }

    @GetMapping("/{id}")
    public CategoryResponse get(@PathVariable Long id) {
        return categories.get(id);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public CategoryResponse create(@Valid @RequestBody CategoryRequest request) {
        return categories.create(request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public CategoryResponse update(@PathVariable Long id, @Valid @RequestBody CategoryRequest request) {
        return categories.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        categories.delete(id);
        return ResponseEntity.noContent().build();
    }
}
