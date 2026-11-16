package br.edu.ifsp.doa.api.security;

import br.edu.ifsp.doa.api.domain.UserRole;

/** Usuário autenticado (principal da requisição). */
public record AuthUser(Long id, String email, UserRole role) {}
