package com.maydevs.dragonball.controller;

import com.maydevs.dragonball.dto.CharacterDetailDto;
import com.maydevs.dragonball.service.CharacterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/characters")
@RequiredArgsConstructor
@Tag(name = "Characters", description = "Dragon Ball Characters endpoints")
public class CharacterController {

    private final CharacterService characterService;

    @GetMapping
    @Operation(summary = "Get characters paginated or filtered")
    public ResponseEntity<Object> getCharacters(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) String race,
            @RequestParam(required = false) String affiliation
    ) {
        Object response = characterService.getCharacters(page, limit, name, gender, race, affiliation);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get character dossier by ID")
    public ResponseEntity<CharacterDetailDto> getCharacterById(@PathVariable Long id) {
        return ResponseEntity.ok(characterService.getCharacterById(id));
    }
}