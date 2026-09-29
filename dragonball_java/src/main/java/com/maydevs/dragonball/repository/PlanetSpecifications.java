package com.maydevs.dragonball.repository;

import com.maydevs.dragonball.entity.PlanetEntity;
import org.springframework.data.jpa.domain.Specification;

public final class PlanetSpecifications {

    private PlanetSpecifications() {}

    public static Specification<PlanetEntity> hasName(String name) {
        return (root, query, cb) -> (name == null || name.isBlank())
                ? cb.conjunction()
                : cb.like(cb.lower(root.get("name")), "%" + name.trim().toLowerCase() + "%");
    }

    public static Specification<PlanetEntity> hasDestroyedStatus(Boolean isDestroyed) {
        return (root, query, cb) -> (isDestroyed == null)
                ? cb.conjunction()
                : cb.equal(root.get("isDestroyed"), isDestroyed);
    }
}