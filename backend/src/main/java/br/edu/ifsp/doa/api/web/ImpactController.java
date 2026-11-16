package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.ImpactService;
import br.edu.ifsp.doa.api.web.dto.MiscDtos.ImpactResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/impact")
public class ImpactController {
    private final ImpactService impact;

    public ImpactController(ImpactService impact) {
        this.impact = impact;
    }

    @GetMapping
    public ImpactResponse summary(@AuthenticationPrincipal AuthUser user) {
        return impact.summary(user);
    }
}
