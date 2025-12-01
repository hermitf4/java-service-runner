# service-router

## Overview

`service-router` is a lightweight and generic routing module that provides a unified HTTP entrypoint for multiple backend microservices.  
It is built using **Java 23**, **Spring Boot 3.4.x**, and **Spring Cloud Gateway**, and is designed to be deployed inside the `JavaServiceRunner` environment.

By placing the compiled router JAR into the `services` directory, all configured microservices can be reached through a single centralized URL.

## Features

- Centralized routing for multiple backend services
- Fully configurable through `application.yml`
- High-performance routing powered by Spring Cloud Gateway
- Supports path-based routing and URI forwarding
- Distributed as a standalone JAR, deployable in any JavaServiceRunner installation
- Completely generic and not tied to any specific application domain

## Requirements

Ensure the following tools are installed and available in your system PATH:

- **Java 23**
- **Apache Maven 3.9.9**

Check installation with:

```
java --version
mvn --version
```

## Building the Project
Compile the project using Maven:

```
mvn clean install
```

After compilation, the runnable JAR will be available at:

```
target/service-router-*.jar
```

## Deploying the Router JAR

To enable the router inside **JavaServiceRunner**, copy the generated JAR to:

```
JavaServiceRunner/services/
```

Example:

```
JavaServiceRunner/
 ├── services/
 │    └── service-router-1.0.0.jar
```

The JavaServiceRunner will detect and start the router automatically via its startup script.

## Routing Configuration

Routing rules for microservices must be defined in:

```
src/main/resources/application.yml
```

A predefined template is provided:

```
application-template.yml
```

Copy it and rename it as follows:
```
cp application-template.yml src/main/resources/application.yml
```

**Example routing configuration**
```
server:
  port: 9012

spring:
  cloud:
    gateway:

      routes:

        - id: service1
          uri: http://localhost:8081
          predicates:
            - Path=/service1/**

        - id: service2
          uri: http://localhost:8082
          predicates:
            - Path=/service2/**
```
**Customizable fields**
You can freely customize:

- port of the router
- backend service URLs
- mapping paths
- number of routes

## Simply duplicate the route block for additional services.

Optional: Automated Deployment of the JAR

The project provides a Maven Antrun task for automatically deploying the compiled JAR into a directory defined inside your ~/.m2/settings.xml.

Run:

```
mvn antrun:run@manual-move-jar
```

**Maven Settings Example**
```
<profile>
    <id>local-deploy</id>
    <properties>
        <deploy.output.dir>C:\Users\USER\MY\environment\services</deploy.output.dir>
    </properties>
</profile>

<activeProfiles>
    <activeProfile>local-deploy</activeProfile>
</activeProfiles>
```

When the profile is active, executing the deployment task will automatically copy the built JAR to the specified folder.

## Directory Structure
```
service-router/
 ├── pom.xml
 ├── application-template.yml
 ├── README.md
 │
 └── src/
     └── main/
         ├── java/
         │   └── com/
         │       └── servicerouter/
         │           └── ServiceRouterApplication.java
         │
         └── resources/
             └── application.yml   (created by the user)
```
## Notes
- The router module is optional. If no router JAR is placed in the services directory, the JavaServiceRunner will simply skip it.
- Leave business logic to backend microservices; the router acts only as a request forwarder.
- After modifying routing rules, recompile and redeploy the service-router JAR.
- The module is intentionally generic and reusable across different projects.
