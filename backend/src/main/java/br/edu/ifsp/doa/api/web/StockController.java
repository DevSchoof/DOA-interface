package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.StockService;
import br.edu.ifsp.doa.api.web.dto.StockDtos.StockRequest;
import br.edu.ifsp.doa.api.web.dto.StockDtos.StockResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stock")
@PreAuthorize("hasRole('INSTITUTION')")
public class StockController {
    private final StockService stock;

    public StockController(StockService stock) {
        this.stock = stock;
    }

    @GetMapping
    public List<StockResponse> list(@AuthenticationPrincipal AuthUser user) {
        return stock.list(user.id());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StockResponse create(@AuthenticationPrincipal AuthUser user, @Valid @RequestBody StockRequest request) {
        return stock.create(user.id(), request);
    }

    @PutMapping("/{id}")
    public StockResponse update(@AuthenticationPrincipal AuthUser user, @PathVariable Long id,
                                @Valid @RequestBody StockRequest request) {
        return stock.update(user.id(), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        stock.delete(user.id(), id);
        return ResponseEntity.noContent().build();
    }
}
