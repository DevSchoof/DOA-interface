package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.util.HashSet;
import java.util.Set;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "institutions")
@Getter @Setter @NoArgsConstructor
public class Institution {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true, length = 14)
    private String cnpj;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private String city;

    @Column(nullable = false)
    private String areaOfActivity;

    @Column(nullable = false)
    private double storageCapacityKg;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InstitutionStatus status = InstitutionStatus.PENDING;

    private String rejectionReason;

    private Double latitude;
    private Double longitude;

    /** N:N: categorias de alimento que a instituição aceita receber. */
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "institution_category",
        joinColumns = @JoinColumn(name = "institution_id"),
        inverseJoinColumns = @JoinColumn(name = "category_id"))
    private Set<FoodCategory> categories = new HashSet<>();
}
