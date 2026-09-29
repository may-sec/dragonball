package com.maydevs.dragonball.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.maydevs.dragonball.entity.CharacterEntity;
import com.maydevs.dragonball.entity.PlanetEntity;
import com.maydevs.dragonball.entity.TransformationEntity;
import com.maydevs.dragonball.repository.CharacterRepository;
import com.maydevs.dragonball.repository.PlanetRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final PlanetRepository planetRepository;
    private final CharacterRepository characterRepository;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private static final String API_BASE = "https://dragonball-api.com/api";

    @Override
    @Transactional
    public void run(String... args) {
        // Guard check: If database is already populated, skip execution
        if (planetRepository.count() > 0 && characterRepository.count() > 0) {
            log.info("Database already contains data ({} planets, {} characters). Skipping import.",
                    planetRepository.count(), characterRepository.count());
            return;
        }

        log.info("Starting automatic data fetch from public API to populate PostgreSQL...");

        Map<Long, PlanetEntity> planetMap = new HashMap<>();

        try {
            // 1. Fetch and save all 20 Planets
            String planetsUrl = API_BASE + "/planets?limit=50";
            ResponseEntity<String> planetResp = restTemplate.getForEntity(planetsUrl, String.class);
            JsonNode planetRoot = objectMapper.readTree(planetResp.getBody());
            JsonNode planetItems = planetRoot.get("items");

            if (planetItems != null && planetItems.isArray()) {
                for (JsonNode pNode : planetItems) {
                    PlanetEntity planet = PlanetEntity.builder()
                            .id(pNode.get("id").asLong())
                            .name(pNode.get("name").asText("Unknown"))
                            .isDestroyed(pNode.hasNonNull("isDestroyed") && pNode.get("isDestroyed").asBoolean())
                            .description(pNode.hasNonNull("description") ? pNode.get("description").asText() : "")
                            .image(pNode.hasNonNull("image") ? pNode.get("image").asText() : "")
                            .characters(new ArrayList<>())
                            .build();

                    PlanetEntity saved = planetRepository.save(planet);
                    planetMap.put(saved.getId(), saved);
                }
            }
            log.info("Saved {} planets into database.", planetMap.size());

            // 2. Fetch all 58 Characters
            String charactersUrl = API_BASE + "/characters?limit=100";
            ResponseEntity<String> charResp = restTemplate.getForEntity(charactersUrl, String.class);
            JsonNode charRoot = objectMapper.readTree(charResp.getBody());
            JsonNode charItems = charRoot.get("items");

            if (charItems != null && charItems.isArray()) {
                for (JsonNode cSummary : charItems) {
                    long charId = cSummary.get("id").asLong();

                    // Query character detail endpoint for nested transformations and planet origin
                    String detailUrl = API_BASE + "/characters/" + charId;
                    try {
                        ResponseEntity<String> detailResp = restTemplate.getForEntity(detailUrl, String.class);
                        JsonNode dNode = objectMapper.readTree(detailResp.getBody());

                        PlanetEntity originPlanet = null;
                        if (dNode.hasNonNull("originPlanet")) {
                            long pId = dNode.get("originPlanet").get("id").asLong();
                            originPlanet = planetMap.get(pId);
                        }

                        CharacterEntity character = CharacterEntity.builder()
                                .id(charId)
                                .name(dNode.get("name").asText("Unknown"))
                                .ki(dNode.hasNonNull("ki") ? dNode.get("ki").asText() : "0")
                                .maxKi(dNode.hasNonNull("maxKi") ? dNode.get("maxKi").asText() : "0")
                                .race(dNode.hasNonNull("race") ? dNode.get("race").asText() : "Unknown Race")
                                .gender(dNode.hasNonNull("gender") ? dNode.get("gender").asText() : "Unknown")
                                .description(dNode.hasNonNull("description") ? dNode.get("description").asText() : "")
                                .image(dNode.hasNonNull("image") ? dNode.get("image").asText() : "")
                                .affiliation(dNode.hasNonNull("affiliation") ? dNode.get("affiliation").asText() : "None")
                                .originPlanet(originPlanet)
                                .transformations(new ArrayList<>())
                                .build();

                        // Parse transformations
                        if (dNode.has("transformations") && dNode.get("transformations").isArray()) {
                            for (JsonNode tNode : dNode.get("transformations")) {
                                TransformationEntity trans = TransformationEntity.builder()
                                        .id(tNode.get("id").asLong())
                                        .name(tNode.get("name").asText("Unknown Form"))
                                        .image(tNode.hasNonNull("image") ? tNode.get("image").asText() : "")
                                        .ki(tNode.hasNonNull("ki") ? tNode.get("ki").asText() : "0")
                                        .character(character)
                                        .build();
                                character.getTransformations().add(trans);
                            }
                        }

                        characterRepository.save(character);
                        log.info("Saved character: {} (ID: {})", character.getName(), charId);

                    } catch (Exception ex) {
                        log.error("Failed saving character ID {}: {}", charId, ex.getMessage());
                    }
                }
            }

            log.info("Data import complete! PostgreSQL now contains {} planets and {} characters.",
                    planetRepository.count(), characterRepository.count());

        } catch (Exception e) {
            log.error("Error during initial data import: ", e);
        }
    }
}