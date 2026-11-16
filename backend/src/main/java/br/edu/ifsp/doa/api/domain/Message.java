package br.edu.ifsp.doa.api.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Mensagem do chat entre o doador e a instituição que reservou a doação. */
@Entity
@Table(name = "messages")
@Getter @Setter @NoArgsConstructor
public class Message {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Donation donation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private User sender;

    @Column(nullable = false, length = 1000)
    private String content;

    @Column(nullable = false)
    private LocalDateTime sentAt = LocalDateTime.now();
}
