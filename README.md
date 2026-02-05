# SE Textbook Library

A Spring Boot application for browsing software engineering textbooks, with MongoDB backend.

---

## Requirements

- **Java 17+**
- **Maven 3.9+**
- **MongoDB** (local or Docker)
- **Docker** (for integration tests) 

### Java Installation

- **Windows**: Download from [Adoptium](https://adoptium.net/) or use `winget install Microsoft.OpenJDK.17`
- **macOS**: `brew install openjdk@17`
- **Ubuntu**: `sudo apt install openjdk-17-jdk`

Verify installation:
```bash
java --version
mvn --version
```

---

## Quick Start

### 1. Start MongoDB

**Using systemctl (Linux)**
```bash
sudo systemctl start mongod
```


### 2. Run the Application

```bash
mvn spring-boot:run
```

### 3. Access the Application

Open http://localhost:3001 in your browser.

This is a very simple application for learning pipeline. Check that the application work by typing in random value into the inte


---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Web UI |
| POST | `/textbook` | Get textbook by ID |
| GET | `/os` | Get hostname & environment |
| GET | `/live` | Liveness probe |
| GET | `/ready` | Readiness probe |

---

## CI/CD Pipeline (Jenkins)

Our goal will be to add Jenkinfile that will have the following:
1. **Build** - Compile the application
2. **OWASP Dependency Check** - Security scanning
3. **Unit Tests** - Fast tests with mocked DB
4. **Integration Tests** - Real MongoDB via Testcontainers
5. **Code Coverage** - JaCoCo report
6. **SAST** - SonarQube analysis
7. **Package** - Build JAR artifact

