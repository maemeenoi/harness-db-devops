# Liquibase on Debian base (with Bash + certs)
FROM eclipse-temurin:17-jre

ARG LB_VERSION=4.27.0

# Install curl, unzip, bash, and CA certs
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    bash \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install Liquibase
RUN curl -fsSL "https://github.com/liquibase/liquibase/releases/download/v${LB_VERSION}/liquibase-${LB_VERSION}.zip" -o /tmp/liquibase.zip \
 && unzip /tmp/liquibase.zip -d /opt/liquibase \
 && ln -s /opt/liquibase/liquibase /usr/local/bin/liquibase \
 && chmod +x /opt/liquibase/liquibase

# Set shell to bash for compatibility
SHELL ["/bin/bash", "-c"]

# Default command for testing
CMD ["bash", "-lc", "liquibase --version"]
