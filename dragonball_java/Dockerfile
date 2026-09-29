# syntax=docker/dockerfile:1.7

# ===========================
# 1. Build Stage
# ===========================
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Copy Maven wrapper and POM configuration
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

# Pre-fetch project dependencies and plugins using build cache
RUN --mount=type=cache,id=maven-repo,target=/root/.m2 \
    ./mvnw dependency:resolve dependency:resolve-plugins -B

# Copy project source code
COPY src/ ./src/

# Package executable JAR using cached .m2 directory
RUN --mount=type=cache,id=maven-repo,target=/root/.m2 \
    ./mvnw package -DskipTests -B

# ===========================
# 2. Runtime Stage
# ===========================
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

ENV SPRING_PROFILES_ACTIVE=prod \
    PORT=8080 \
    JAVA_TOOL_OPTIONS="-XX:+ExitOnOutOfMemoryError -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Create dedicated non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy JAR directly with correct user ownership in a single layer
COPY --from=build --chown=appuser:appgroup /app/target/*.jar app.jar

# Drop root privileges
USER appuser:appgroup

EXPOSE ${PORT}

# Healthcheck aligned with Spring Actuator or Dragon Ball character browse endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]