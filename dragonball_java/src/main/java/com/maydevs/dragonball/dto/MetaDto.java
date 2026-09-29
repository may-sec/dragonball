package com.maydevs.dragonball.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MetaDto {
    private long totalItems;
    private int itemCount;
    private int itemsPerPage;
    private int totalPages;
    private int currentPage;
}