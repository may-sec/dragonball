package com.maydevs.dragonball.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "planets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PlanetEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Boolean isDestroyed;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false)
    private String image;

    private LocalDateTime deletedAt;

    @OneToMany(mappedBy = "originPlanet", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<CharacterEntity> characters = new ArrayList<>();
}