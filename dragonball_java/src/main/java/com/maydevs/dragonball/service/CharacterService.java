package com.maydevs.dragonball.service;

import com.maydevs.dragonball.dto.*;
import com.maydevs.dragonball.entity.CharacterEntity;
import com.maydevs.dragonball.entity.PlanetEntity;
import com.maydevs.dragonball.entity.TransformationEntity;
import com.maydevs.dragonball.exception.ResourceNotFoundException;
import com.maydevs.dragonball.repository.CharacterRepository;
import com.maydevs.dragonball.repository.CharacterSpecifications;
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
public class CharacterService {

    private final CharacterRepository characterRepository;

    @Value("${app.base-url:http://localhost:8080}")
    private String baseUrl;

    @Transactional(readOnly = true)
    public Object getCharacters(int page, int limit, String name, String gender, String race, String affiliation) {
        boolean isFiltered = (name != null && !name.isBlank()) ||
                             (gender != null && !gender.isBlank() && !"ALL".equalsIgnoreCase(gender)) ||
                             (race != null && !race.isBlank() && !"ALL".equalsIgnoreCase(race)) ||
                             (affiliation != null && !affiliation.isBlank() && !"ALL".equalsIgnoreCase(affiliation));

        Specification<CharacterEntity> spec = Specification
                .where(CharacterSpecifications.hasName(name))
                .and(CharacterSpecifications.hasGender(gender))
                .and(CharacterSpecifications.hasRace(race))
                .and(CharacterSpecifications.hasAffiliation(affiliation));

        // Asymmetrical contract: Flat array if filtered
        if (isFiltered) {
            List<CharacterEntity> matched = characterRepository.findAll(spec);
            return matched.stream().map(this::toSummaryDto).toList();
        }

        // 1-based page conversion to Spring Data's 0-based index
        int safePage = Math.max(page, 1);
        int safeLimit = Math.max(limit, 1);
        Pageable pageable = PageRequest.of(safePage - 1, safeLimit);

        Page<CharacterEntity> pageResult = characterRepository.findAll(spec, pageable);

        List<CharacterSummaryDto> items = pageResult.getContent().stream()
                .map(this::toSummaryDto)
                .toList();

        MetaDto meta = MetaDto.builder()
                .totalItems(pageResult.getTotalElements())
                .itemCount(items.size())
                .itemsPerPage(safeLimit)
                .totalPages(pageResult.getTotalPages())
                .currentPage(safePage)
                .build();

        String endpoint = baseUrl + "/api/characters";
        LinksDto links = LinksDto.builder()
                .first(endpoint + "?limit=" + safeLimit)
                .previous(safePage > 1 ? endpoint + "?page=" + (safePage - 1) + "&limit=" + safeLimit : "")
                .next(safePage < pageResult.getTotalPages() ? endpoint + "?page=" + (safePage + 1) + "&limit=" + safeLimit : "")
                .last(endpoint + "?page=" + pageResult.getTotalPages() + "&limit=" + safeLimit)
                .build();

        return PagedResponseDto.<CharacterSummaryDto>builder()
                .items(items)
                .meta(meta)
                .links(links)
                .build();
    }

    @Transactional(readOnly = true)
    public CharacterDetailDto getCharacterById(Long id) {
        CharacterEntity entity = characterRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Character not found with id: " + id));

        return toDetailDto(entity);
    }

    public CharacterSummaryDto toSummaryDto(CharacterEntity e) {
        return CharacterSummaryDto.builder()
                .id(e.getId())
                .name(e.getName())
                .ki(e.getKi())
                .maxKi(e.getMaxKi())
                .race(e.getRace())
                .gender(e.getGender())
                .description(e.getDescription())
                .image(e.getImage())
                .affiliation(e.getAffiliation())
                .deletedAt(e.getDeletedAt())
                .build();
    }

    private CharacterDetailDto toDetailDto(CharacterEntity e) {
        PlanetSummaryDto planetDto = null;
        if (e.getOriginPlanet() != null) {
            PlanetEntity p = e.getOriginPlanet();
            planetDto = PlanetSummaryDto.builder()
                    .id(p.getId())
                    .name(p.getName())
                    .isDestroyed(p.getIsDestroyed())
                    .description(p.getDescription())
                    .image(p.getImage())
                    .deletedAt(p.getDeletedAt())
                    .build();
        }

        List<TransformationDto> transformations = e.getTransformations().stream()
                .map(this::toTransformationDto)
                .toList();

        return CharacterDetailDto.builder()
                .id(e.getId())
                .name(e.getName())
                .ki(e.getKi())
                .maxKi(e.getMaxKi())
                .race(e.getRace())
                .gender(e.getGender())
                .description(e.getDescription())
                .image(e.getImage())
                .affiliation(e.getAffiliation())
                .deletedAt(e.getDeletedAt())
                .originPlanet(planetDto)
                .transformations(transformations)
                .build();
    }

    private TransformationDto toTransformationDto(TransformationEntity t) {
        return TransformationDto.builder()
                .id(t.getId())
                .name(t.getName())
                .image(t.getImage())
                .ki(t.getKi())
                .deletedAt(t.getDeletedAt())
                .build();
    }
}