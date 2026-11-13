package br.edu.ifsp.doa.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "doa")
public record AppProperties(Jwt jwt, Seed seed, Fcm fcm, int reservationHours, double defaultRadiusKm) {
    public record Jwt(String secret, int expirationHours) {}
    public record Seed(boolean demo, String adminEmail, String adminPassword) {}
    public record Fcm(String credentialsJson, String credentialsPath) {}
}
