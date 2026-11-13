package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "food_categories")
@Getter @Setter @NoArgsConstructor
public class FoodCategory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 60)
    private String name;

    @Column(length = 200)
    private String description;

    @Column(nullable = false)
    private boolean active = true;

    public FoodCategory(String name, String description) {
        this.name = name;
        this.description = description;
    }
}
