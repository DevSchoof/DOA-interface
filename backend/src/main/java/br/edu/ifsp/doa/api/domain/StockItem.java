package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "stock_items")
@Getter @Setter @NoArgsConstructor
public class StockItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Institution institution;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private FoodCategory category;

    @Column(nullable = false, length = 120)
    private String description;

    @Column(nullable = false)
    private double quantity;

    @Column(nullable = false, length = 5)
    private String unit;

    @Column(nullable = false)
    private LocalDateTime receivedAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDate expiresAt;
}
