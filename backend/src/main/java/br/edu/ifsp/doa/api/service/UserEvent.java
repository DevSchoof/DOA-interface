package br.edu.ifsp.doa.api.service;

import java.util.Map;

/**
 * Evento para um usuário. Se `payload` existir, vai pelo WebSocket; se houver
 * título e token FCM, também vira push no celular. Só é entregue após o commit.
 */
public record UserEvent(Long userId, String fcmToken, Map<String, Object> payload, String pushTitle, String pushBody) {}
