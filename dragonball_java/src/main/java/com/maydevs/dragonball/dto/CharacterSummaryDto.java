package com.maydevs.dragonball.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class CharacterSummaryDto {
    private Long id;
    private String name;
    private String ki;
    private String maxKi;
    private String race;
    private String gender;
    private String description;
    private String image;
    private String affiliation;
    private LocalDateTime deletedAt;
}