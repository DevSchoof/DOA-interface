package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Foto de uma doação (relação 1:N com Donation). O arquivo fica no próprio banco (LONGBLOB no MySQL),
 * porque hospedagens gratuitas apagam o disco a cada reinício. O id é um UUID para que a URL pública
 * da imagem não possa ser adivinhada.
 */
@Entity
@Table(name = "donation_photos", indexes = @Index(name = "idx_photo_donation", columnList = "donation_id"))
@Getter @Setter @NoArgsConstructor
public class DonationPhoto {
    @Id
    @Column(length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "donation_id", nullable = false)
    private Donation donation;

    @Column(nullable = false, length = 30)
    private String contentType;

    @Column(nullable = false)
    private long sizeBytes;

    // LONGBLOB explícito: sem isso o Hibernate cria um blob pequeno no MySQL e a foto não cabe
    @Column(nullable = false, columnDefinition = "LONGBLOB")
    private byte[] data;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
