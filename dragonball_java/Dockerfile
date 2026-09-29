# syntax=docker/dockerfile:1.7

# ===========================
# 1. Build Stage
# ===========================
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

# Pre-fetch project dependencies and build plugins
RUN --mount=type=cache,id=maven-repo,target=/root/.m2 \
    ./mvnw dependency:resolve dependency:resolve-plugins -B

COPY src/ ./src/

# Package without wiping cached dependencies
RUN --mount=type=cache,id=maven-repo,target=/root/.m2 \
    ./mvnw package -DskipTests -B

# ===========================
# 2. Runtime Stage
# ===========================
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

ENV SPRING_PROFILES_ACTIVE=prod
ENV PORT=8080

# Create non-root user group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# COPY FIRST as root so permissions are guaranteed, then assign ownership
COPY --from=build /app/target/*.jar app.jar
RUN chown appuser:appgroup app.jar

# Now switch to non-root user
USER appuser:appgroup

EXPOSE ${PORT}

# Native healthcheck using dynamic ${PORT}
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/api/v1/entries?size=1 || exit 1

ENTRYPOINT ["java", "-XX:+ExitOnOutOfMemoryError", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]