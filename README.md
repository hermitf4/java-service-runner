# JavaServiceRunner
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## 1. Introduction

`JavaServiceRunner` is a utility project designed to **start** and **stop** multiple Java modules packaged as `.jar` files.

The runner is intended for:

- **Windows 10 / 11** environments  
- Services developed with **Java 23** (typically Spring Boot 3.x, but not limited to it)  
- Scenarios requiring minimal and structured multi-service management (PID handling, logs, centralized start/stop)

Compared to the initial version (originally created for the *Almadoc 1.0* project), the structure has been fully generalized so it can be used with **any set of Java modules**.

----------

## 2. Main Features

- Starts all `.jar` files located in a configurable directory (`services.dir`)
- Generates a dedicated `.pid` file for each running service
- Redirects standard output and errors into `.out` log files
- Detects already-running services via PID lookup (skipping them during start)
- Stops:
  - all services managed by the runner (mass mode)
  - a single service by PID (PID-only mode)
- External configuration via `services-runner.cfg`
- Optional integration with the **ServiceRouter** module to expose a unified HTTP entrypoint

----------

## 3. Project Structure

Recommended repository structure:

```
JavaServiceRunner/
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
│
├── bin/
│   ├── start-services.bat
│   ├── stop-services.bat
│   └── services-runner.cfg
│
├── services/
│   ├── service-a.jar
│   ├── service-b.jar
│   └── service-router-1.0.0.jar   (optional)
│
├── logs/
│   ├── service-a.pid
│   ├── service-a.out
│   └── ...
│
└── ServiceRouter/
    ├── pom.xml
    ├── application-template.yml
    └── src/
        └── main/...
```

**Folder overview**
- bin/ – Contains startup/shutdown scripts (start-services.bat, stop-services.bat) and services-runner.cfg.
- services/ – Contains all .jar files to be executed (including the optional service-router jar).
- logs/ – Stores PID files and .out runtime logs.
- ServiceRouter/ – Optional Java module (Spring Boot + Spring Cloud Gateway) acting as an HTTP proxy/gateway.

----------

## 4. Requirements

Before using the runner, ensure that:

1.  **Java 23** is installed and available in your `PATH`:

    `java --version` 

2.  All service `.jar` files are compiled and placed inside the directory defined by `services.dir` (default: `services/`).

3.  (Optional) To compile **ServiceRouter**, you need **Apache Maven 3.9.9**:

    `mvn --version`

----------

## 5. Runner Configuration (`services-runner.cfg`)

The runner behavior is controlled through:

`bin/services-runner.cfg` 

File format (key=value):

`# Directory containing service JAR files  # May be absolute or relative to the project root  services.dir=services # Directory containing .pid files and .out logs  logs.dir=logs # Optional JVM options applied to all services java.opts=` 

### Notes

-   Missing entries fall back to defaults (`services` and `logs`).
-   Paths may be **relative** (recommended) or **absolute**.

----------

## 6. Starting Services (`start-services.bat`)

### 6.1 Location and usage

Script location:

`bin/start-services.bat` 

To execute it:

`cd C:\path\to\JavaServiceRunner
bin\start-services.bat` 

### 6.2 What the script does

1.  Determines the project root directory (parent of `bin/`)
2.  Loads configuration from `services-runner.cfg`
3.  Resolves:
    -   `SERVICES_DIR` ← config or default
    -   `LOG_DIR` ← config or default
4.  Ensures directories exist
5.  Lists all `*.jar` files in `SERVICES_DIR`
6.  For each JAR:
    -   Extracts the service name
    -   Generates PID file path
    -   If a PID exists and the process is still running → **skips**
    -   Otherwise starts the service:
        `java %JAVA_OPTS% -jar "<SERVICES_DIR>\<jarname>.jar" --spring.pid.file="<LOG_DIR>\<servicename>.pid"` 
        Output is redirected to `<LOG_DIR>\<servicename>.out`.
7.  Displays final PID status for each service.

----------

## 7. Stopping Services (`stop-services.bat`)

Script location:

`bin/stop-services.bat` 

Two operation modes are supported.

### 7.1 Mass mode (stop all services)

`bin\stop-services.bat` 

Flow:

1.  Loads config and folder paths

2.  Lists all `*.jar` in `SERVICES_DIR`

3.  For each service:

    -   Reads PID file if exists

    -   Verifies if the PID corresponds to a running Java process

    -   Uses:

        `taskkill /PID <PID> /F` 

    -   Deletes the `.pid` file

### 7.2 PID-only mode (stop a single process)

If a single numeric argument is passed:

`bin\stop-services.bat 12345` 

The script:

-   Searches for the `.pid` file containing PID `12345`
    
-   If found and active → kills it
    
-   If not found → prints an error without touching other services

### 7.3 Overriding directories

You may override service/log directories:

`bin\stop-services.bat C:\custom\services C:\custom\logs` 

Or combine with PID-only mode:

`bin\stop-services.bat C:\services C:\logs 12345` 

----------

## 8. Logs and Diagnostics

Each service produces:

-   **`<servicename>.out`**  
    Runtime output (stdout + stderr)
    
-   **`<servicename>.pid`**  
    Process ID of the running service

Standard log prefixes:

-   `[INFO]` – informative events
    
-   `[WARN]` – non-blocking irregularities
    
-   `[ERROR]` – blocking errors
    

----------

## 9. Optional Integration: `ServiceRouter`

The **ServiceRouter** module is an optional Spring Boot application using Spring Cloud Gateway to expose a **single entrypoint** for multiple backend services.

Location:

`JavaServiceRunner/ServiceRouter/` 

### 9.1 Building the router

`cd ServiceRouter
mvn clean install` 

Copy the resulting `service-router-<version>.jar` into your `services/` directory.

### 9.2 Route configuration

Routes are defined in:

`ServiceRouter/src/main/resources/application.yml` 

Use `application-template.yml` as a starting point.

The router is executed by the runner exactly like all other service JARs.

----------

## 10. Compatibility

-   **OS:** Windows 10, Windows 11
-   **Shell:** `cmd.exe` (officially supported), PowerShell compatible
-   **Permissions:** Administrator privileges only required to stop elevated processes

----------

## 11. Contributing

Contributions are welcome.

Key guidelines:

-   Ensure compatibility with Windows batch scripting
    
-   Do not alter the contract of the configuration file
    
-   Keep scripts resilient when using relative paths
    
-   Document significant changes in `README.md`
    

See:

`CONTRIBUTING.md` 

----------

## 12. License

The project is distributed under the **MIT License**.

Full text available in:

`LICENSE` 

Summary:

-   You may use, modify, merge, publish, distribute, sublicense, and/or sell copies
    
-   You must preserve the copyright notice and license text
    
-   Software is provided “as is”, without warranty
