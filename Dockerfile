# Use an official OpenJDK image as base
FROM openjdk:17-jdk-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Install Liquibase
ENV LIQUIBASE_VERSION=4.25.1
RUN mkdir -p /opt/liquibase && \
    wget https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz -C /opt/liquibase && \
    chmod +x /opt/liquibase/liquibase && \
    ln -s /opt/liquibase/liquibase /usr/local/bin/liquibase && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Install Flyway CLI
ENV FLYWAY_VERSION=10.13.0
RUN wget https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz && \
    tar -xzf flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz && \
    mv flyway-${FLYWAY_VERSION} /opt/flyway && \
    rm flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz

ENV PATH="/opt/flyway:${PATH}"

# Default command
CMD ["bash"]