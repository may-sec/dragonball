package com.maydevs.dragonball.repository;

import com.maydevs.dragonball.entity.PlanetEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface PlanetRepository extends JpaRepository<PlanetEntity, Long>, JpaSpecificationExecutor<PlanetEntity> {
}