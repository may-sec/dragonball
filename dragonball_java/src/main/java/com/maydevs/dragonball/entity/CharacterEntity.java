package com.maydevs.dragonball.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "characters")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CharacterEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String ki;

    @Column(nullable = false)
    private String maxKi;

    @Column(nullable = false)
    private String race;

    @Column(nullable = false)
    private String gender;

    @Column(length = 3000)
    private String description;

    @Column(nullable = false)
    private String image;

    @Column(nullable = false)
    private String affiliation;

    private LocalDateTime deletedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "planet_id")
    private PlanetEntity originPlanet;

    @OneToMany(mappedBy = "character", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<TransformationEntity> transformations = new ArrayList<>();
}