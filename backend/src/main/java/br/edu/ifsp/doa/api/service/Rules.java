package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.web.ApiException;
import java.time.LocalDate;
import java.util.Set;

/** Validações de negócio compartilhadas entre doações e estoque. */
final class Rules {
    private static final Set<String> UNITS = Set.of("kg", "un", "L");

    private Rules() {}

    static void requireUnit(String unit) {
        if (!UNITS.contains(unit)) {
            throw ApiException.badRequest("Unidade inválida. Use kg, un ou L.");
        }
    }

    static void requireNotExpired(LocalDate expiresAt) {
        if (expiresAt.isBefore(LocalDate.now())) {
            throw ApiException.badRequest("A validade informada já passou.");
        }
    }
}
