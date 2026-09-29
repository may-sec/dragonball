package com.maydevs.dragonball.controller;

import com.maydevs.dragonball.dto.PlanetDetailDto;
import com.maydevs.dragonball.service.PlanetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/planets")
@RequiredArgsConstructor
@Tag(name = "Planets", description = "Dragon Ball Cosmic Realms endpoints")
public class PlanetController {

    private final PlanetService planetService;

    @GetMapping
    @Operation(summary = "Get planets paginated or filtered")
    public ResponseEntity<Object> getPlanets(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Boolean isDestroyed
    ) {
        Object response = planetService.getPlanets(page, limit, name, isDestroyed);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get planet details and inhabitants by ID")
    public ResponseEntity<PlanetDetailDto> getPlanetById(@PathVariable Long id) {
        return ResponseEntity.ok(planetService.getPlanetById(id));
    }
}