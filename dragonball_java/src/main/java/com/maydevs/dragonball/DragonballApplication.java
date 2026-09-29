package com.maydevs.dragonball;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DragonballApplication {

    public static void main(String[] args) {
        // Load .env from project root if it exists
        Dotenv dotenv = Dotenv.configure()
                .ignoreIfMissing()
                .load();

        dotenv.entries().forEach(entry -> {
            // Set into System properties so Spring Boot can resolve ${SPRING_DATASOURCE_...}
            System.setProperty(entry.getKey(), entry.getValue());
        });

        SpringApplication.run(DragonballApplication.class, args);
    }
}