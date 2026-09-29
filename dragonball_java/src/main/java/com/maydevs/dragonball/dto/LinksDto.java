package com.maydevs.dragonball.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LinksDto {
    private String first;
    private String previous;
    private String next;
    private String last;
}