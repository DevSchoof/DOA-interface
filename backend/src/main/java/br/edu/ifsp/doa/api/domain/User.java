package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserRole role;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /** Tentativas de login seguidas que falharam (bloqueio de 30 min após 3). */
    private int failedAttempts;
    private LocalDateTime lockedUntil;

    /** Token do Firebase Cloud Messaging do aparelho (push). */
    @Column(length = 500)
    private String fcmToken;
}
