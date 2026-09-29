package com.maydevs.dragonball.repository;

import com.maydevs.dragonball.entity.CharacterEntity;
import org.springframework.data.jpa.domain.Specification;

public final class CharacterSpecifications {

    private CharacterSpecifications() {}

    public static Specification<CharacterEntity> hasName(String name) {
        return (root, query, cb) -> (name == null || name.isBlank())
                ? cb.conjunction()
                : cb.like(cb.lower(root.get("name")), "%" + name.trim().toLowerCase() + "%");
    }

    public static Specification<CharacterEntity> hasGender(String gender) {
        return (root, query, cb) -> (gender == null || gender.isBlank() || "ALL".equalsIgnoreCase(gender))
                ? cb.conjunction()
                : cb.equal(cb.lower(root.get("gender")), gender.trim().toLowerCase());
    }

    public static Specification<CharacterEntity> hasRace(String race) {
        return (root, query, cb) -> (race == null || race.isBlank() || "ALL".equalsIgnoreCase(race))
                ? cb.conjunction()
                : cb.equal(cb.lower(root.get("race")), race.trim().toLowerCase());
    }

    public static Specification<CharacterEntity> hasAffiliation(String affiliation) {
        return (root, query, cb) -> (affiliation == null || affiliation.isBlank() || "ALL".equalsIgnoreCase(affiliation))
                ? cb.conjunction()
                : cb.equal(cb.lower(root.get("affiliation")), affiliation.trim().toLowerCase());
    }
}