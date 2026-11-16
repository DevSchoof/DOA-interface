package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "donors")
@Getter @Setter @NoArgsConstructor
public class Donor {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PersonType personType;

    @Column(nullable = false)
    private String name;

    /** CPF (11) ou CNPJ (14), só dígitos. */
    @Column(nullable = false, unique = true, length = 14)
    private String document;

    @Column(nullable = false, length = 11)
    private String phone;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private String city;

    private Double latitude;
    private Double longitude;
}
