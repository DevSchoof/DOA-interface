package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "donations")
@Getter @Setter @NoArgsConstructor
public class Donation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Evita que duas instituições reservem a mesma doação ao mesmo tempo. */
    @Version
    private Long version;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Donor donor;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private FoodCategory category;

    @Column(nullable = false, length = 120)
    private String description;

    @Column(nullable = false)
    private double quantity;

    @Column(nullable = false, length = 5)
    private String unit;

    @Column(nullable = false)
    private LocalDate expiresAt;

    private String storageConditions;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DonationStatus status = DonationStatus.AVAILABLE;

    @ManyToOne(fetch = FetchType.LAZY)
    private Institution reservedBy;

    private LocalDateTime reservedAt;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
