package com.maydevs.dragonball.service;

import com.maydevs.dragonball.dto.*;
import com.maydevs.dragonball.entity.PlanetEntity;
import com.maydevs.dragonball.exception.ResourceNotFoundException;
import com.maydevs.dragonball.repository.PlanetRepository;
import com.maydevs.dragonball.repository.PlanetSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PlanetService {

    private final PlanetRepository planetRepository;
    private final CharacterService characterService;

    @Value("${app.base-url:http://localhost:8080}")
    private String baseUrl;

    @Transactional(readOnly = true)
    public Object getPlanets(int page, int limit, String name, Boolean isDestroyed) {
        boolean isFiltered = (name != null && !name.isBlank()) || (isDestroyed != null);

        Specification<PlanetEntity> spec = Specification
                .where(PlanetSpecifications.hasName(name))
                .and(PlanetSpecifications.hasDestroyedStatus(isDestroyed));

        if (isFiltered) {
            List<PlanetEntity> matched = planetRepository.findAll(spec);
            return matched.stream().map(this::toSummaryDto).toList();
        }

        int safePage = Math.max(page, 1);
        int safeLimit = Math.max(limit, 1);
        Pageable pageable = PageRequest.of(safePage - 1, safeLimit);

        Page<PlanetEntity> pageResult = planetRepository.findAll(spec, pageable);

        List<PlanetSummaryDto> items = pageResult.getContent().stream()
                .map(this::toSummaryDto)
                .toList();

        MetaDto meta = MetaDto.builder()
                .totalItems(pageResult.getTotalElements())
                .itemCount(items.size())
                .itemsPerPage(safeLimit)
                .totalPages(pageResult.getTotalPages())
                .currentPage(safePage)
                .build();

        String endpoint = baseUrl + "/api/planets";
        LinksDto links = LinksDto.builder()
                .first(endpoint + "?limit=" + safeLimit)
                .previous(safePage > 1 ? endpoint + "?page=" + (safePage - 1) + "&limit=" + safeLimit : "")
                .next(safePage < pageResult.getTotalPages() ? endpoint + "?page=" + (safePage + 1) + "&limit=" + safeLimit : "")
                .last(endpoint + "?page=" + pageResult.getTotalPages() + "&limit=" + safeLimit)
                .build();

        return PagedResponseDto.<PlanetSummaryDto>builder()
                .items(items)
                .meta(meta)
                .links(links)
                .build();
    }

    @Transactional(readOnly = true)
    public PlanetDetailDto getPlanetById(Long id) {
        PlanetEntity entity = planetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Planet not found with id: " + id));

        List<CharacterSummaryDto> inhabitants = entity.getCharacters().stream()
                .map(characterService::toSummaryDto)
                .toList();

        return PlanetDetailDto.builder()
                .id(entity.getId())
                .name(entity.getName())
                .isDestroyed(entity.getIsDestroyed())
                .description(entity.getDescription())
                .image(entity.getImage())
                .deletedAt(entity.getDeletedAt())
                .characters(inhabitants)
                .build();
    }

    public PlanetSummaryDto toSummaryDto(PlanetEntity e) {
        return PlanetSummaryDto.builder()
                .id(e.getId())
                .name(e.getName())
                .isDestroyed(e.getIsDestroyed())
                .description(e.getDescription())
                .image(e.getImage())
                .deletedAt(e.getDeletedAt())
                .build();
    }
}