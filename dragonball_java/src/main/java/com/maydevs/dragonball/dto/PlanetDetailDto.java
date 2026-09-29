package com.maydevs.dragonball.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PlanetDetailDto {
    private Long id;
    private String name;
    private Boolean isDestroyed;
    private String description;
    private String image;
    private LocalDateTime deletedAt;
    private List<CharacterSummaryDto> characters;
}