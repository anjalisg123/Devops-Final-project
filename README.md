# Secure CI/CD Pipeline — SE Textbook Library

**Author:** Anjali Gudimani  
**Course:** SE 441 — DevOps  
**Date:** March 16, 2026

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Design Choices](#design-choices)
4. [Pipeline Stages](#pipeline-stages)
5. [Concept Questions (Task 3)](#concept-questions-task-3)
6. [Inline Stage Questions](#inline-stage-questions)
7. [Challenges (Task 4)](#challenges-task-4)

---

## Project Overview

This project implements a secure CI/CD pipeline using Jenkins Declarative Pipeline for a Java/Maven Spring Boot application (SE Textbook Library). The pipeline automates the full software delivery lifecycle: building, testing, security scanning, code quality analysis, containerization, and deployment to AWS.

### Technology Stack

- **Application:** Java 17, Spring Boot 3.5.4, MongoDB
- **CI Server:** Jenkins 2.541.1
- **Build Tool:** Maven 3.x
- **Security Scanning:** OWASP Dependency-Check, SonarQube Community
- **Code Coverage:** JaCoCo
- **Containerization:** Docker, DockerHub
- **Infrastructure:** Terraform, AWS EC2
- **Version Control:** Git, GitHub

---

## Architecture Diagram

![Architecture Diagram](./screenshots/Architecture_Diagram.png)

----

## Design Choices

### Deviations from Reference Pipeline

1. **Java 17 instead of Java 11:** The provided Spring Boot 3.5.4 application requires Java 17 as a minimum. The Jenkins JDK tool was configured as `OpenJDK 17` accordingly.

2. **Multi-platform Docker build:** Since development was done on Apple Silicon (ARM64) and deployment targets AWS EC2 (x86_64/amd64), the Docker Build stage uses `docker buildx build --platform linux/amd64` to ensure cross-platform compatibility.

3. **SSH-based deployment instead of Terraform in Jenkins:** The Deploy to AWS stage uses SSH to pull and run the Docker image on the EC2 instance. Terraform was used locally to provision the infrastructure, and the Jenkins pipeline handles the application deployment via SSH.

4. **Eclipse Temurin base image:** The Dockerfile uses `eclipse-temurin:17-jre` instead of the deprecated `openjdk` Docker images, which are no longer maintained by Oracle.

5. **Tomcat version override:** Overrode the embedded Tomcat version to 10.1.52 in `pom.xml` properties to resolve critical CVEs (CVE-2025-66614 with CVSS 9.1 and CVE-2025-55754 with CVSS 9.6) that were flagged by OWASP Dependency-Check.

6. **Integration test failure handled with catchError:** Integration tests use Testcontainers which requires Docker accessible from the Jenkins agent context. Since this is not always available, the stage is wrapped in `catchError` to mark it as UNSTABLE rather than failing the pipeline.

---

## Pipeline Stages

### Stage A — Checkout
Uses `checkout scm` to clone the repository from the `cicd` branch.
![Stage A](./screenshots/Stage_A.png)

### Stage B — Build
Runs `mvn clean compile` to compile the Java source code.
![Stage A](./screenshots/Stage_B.png)

### Stage C — Dependency Scanning (Parallel)
Two parallel stages:
- **OWASP Dependency-Check:** Scans dependencies for known CVEs using the NVD database. Configured with `-DfailBuildOnCVSS=9` to fail on critical vulnerabilities. Reports are stashed for later publishing.
- **Maven Dependency Audit:** Runs `mvn versions:display-dependency-updates` to show available dependency updates (informational only).
![Stage C](./screenshots/Stage_C.png)

### Stage D — Publish Dependency-Check Results
Unstashes OWASP reports and publishes them via `dependencyCheckPublisher` (XML) and `publishHTML` (HTML report).
![Stage D](./screenshots/Stage_D.png)

![Stage D](./screenshots/Stage_D2.png)

![Stage D](./screenshots/Stage_D3.png)


### Stage E — Unit Tests
Runs `mvn test` with Surefire configured to exclude `**/*IntegrationTests.java`. Publishes JUnit results from `target/surefire-reports/*.xml`.
![Stage E](./screenshots/Stage_E.png)

### Stage F — Integration Tests
Runs `mvn test -Pintegration-tests` using a Maven profile that includes only integration test classes. Wrapped in `catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE')` so failures don't stop the pipeline. Publishes JUnit results.
![Stage F](./screenshots/Stage_F.png)

### Stage G — Code Coverage
Runs `mvn jacoco:report` and publishes the HTML coverage report from `target/site/jacoco/index.html`. Wrapped in `catchError` to avoid blocking later stages.
![Stage G](./screenshots/Stage_G.png)
![Stage G](./screenshots/code_coverage.png)

### Stage H — SAST (SonarQube)
Runs Maven Sonar analysis with JaCoCo coverage data. Uses `withCredentials` to securely reference the SonarQube token stored in Jenkins credentials.
![Stage H](./screenshots/Stage_H.png)
![Stage H](./screenshots/Stage_H2.png)

### Stage I — Package + Artifact
Runs `mvn package -DskipTests` and archives `target/*.jar` as a Jenkins artifact.
![Stage I](./screenshots/Stage_I.png)
![Stage I](./screenshots/Archived_artifact.png)

### Docker Build & Push
Builds a multi-platform (linux/amd64) Docker image and pushes it to DockerHub with both build number and `latest` tags.
![Docker Build & Push](./screenshots/Docker.png)

### Deploy to AWS
SSHs into the EC2 instance and pulls/runs the latest Docker image.
![Deploy to AWS](./screenshots/Deploy.png)

### Health Check
Waits 30 seconds and sends a curl request to the deployed application to verify it is running.
![Health Check](./screenshots/Deploy.png)

### Infrastructure Provisioning - Terraform Output
![Terraform](./screenshots/Terraform-output.webp)

### EC2 instance
![EC2](./screenshots/EC2.webp)

### Containerization & Registry Evidence
![Deploy](./screenshots/Deploy2.png)

![Deploy](./screenshots/Deploy3.png)

![Deploy](./screenshots/Deploy4.png)

![Deploy](./screenshots/Deploy5.png)

---

## Concept Questions (Task 3)

### 1. When should we run parallel execution in Jenkins? What happens if there is a failure in one job?

Parallel execution should be used when stages are independent and don't depend on each other's output, allowing them to run simultaneously to save time. For example, OWASP scanning and Maven dependency audit are independent tasks that can run in parallel. If one parallel branch fails, by default Jenkins marks the overall parallel stage as failed and the other branches still complete. The pipeline behavior after that depends on the `failFast` setting: if `failFast: true` is set, the other parallel branches are aborted immediately on first failure.

### 2. Why do we stash/unstash the Dependency-Check report?

In multi-agent Jenkins environments, each stage may execute on a different agent or workspace. Files generated in one stage are not automatically available to later stages. `stash` saves specified files from the current workspace, and `unstash` restores them in a later stage's workspace. This ensures the Dependency-Check reports generated during scanning are available in the publish stage. With a single Jenkins agent, stash is not strictly necessary since files persist in the same workspace, but it is best practice for portability across different Jenkins configurations.

### 3. What does `catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE')` accomplish?

This directive catches any error thrown in the enclosed block and prevents it from failing the entire pipeline. Instead of marking the overall build as FAILED, it keeps `buildResult` as SUCCESS while marking only the specific `stageResult` as UNSTABLE (shown as yellow/orange in Jenkins). This is useful for quality signal stages (like code coverage or integration tests) where you want to flag issues without stopping later stages like packaging and deployment.

### 4. Why is `jacoco.xml` useful for SonarQube?

The `jacoco.xml` file contains machine-readable code coverage data that SonarQube can import and display alongside its static analysis results. This allows SonarQube to show coverage metrics in its dashboard, correlate coverage with code quality issues, and enforce coverage thresholds through Quality Gates. Without this file, SonarQube can still perform static analysis but won't have coverage data to display or enforce.

### 5. What is the difference between archiving artifacts vs just "files existing in the workspace"?

Files in the workspace are temporary — they exist only until the workspace is cleaned, reused by another build, or the agent is recycled. Archived artifacts are permanently stored by Jenkins and attached to the specific build record. They can be downloaded at any time from the build page, referenced by downstream jobs, and survive workspace cleanup. Archiving ensures important outputs (like JAR files) are preserved as part of the build's permanent record.

### 6. If the build fails, what is the first place you look?

The first place to look is the **Jenkins Console Output** for the specific build. Click on the failed build number, then Console Output. This shows the complete log of every command executed, including error messages, stack traces, and the exact step where the failure occurred. You can also click on the specific failed stage in the pipeline view to jump directly to that stage's logs.

---

## Inline Stage Questions

### Stage C — Does the build fail from running OWASP?

Yes, the initial OWASP scan caused a build failure. The scan identified critical vulnerabilities in `tomcat-embed-core-10.1.43.jar`: CVE-2025-66614 (CVSS 9.1) and CVE-2025-55754 (CVSS 9.6). These exceeded the `-DfailBuildOnCVSS=9` threshold. The fix was to override the Tomcat version in `pom.xml` by adding `<tomcat.version>10.1.52</tomcat.version>` in the properties section, which pulled in the patched Tomcat release.
![Stage C](./screenshots/Stage_C2.png)

### Stage C — What problem does dependency scanning solve that unit testing cannot detect?

Dependency scanning identifies known security vulnerabilities (CVEs) in third-party libraries that a project uses. Unit tests verify code logic and behavior but cannot detect if a library has a known security flaw. For example, a project using an older version of Apache Tomcat (affected by CVE-2025-55754, a critical authentication bypass) would pass all unit tests because the web server functionality works correctly. However, a dependency scan flags the vulnerability because it checks the library version against the NVD database of known CVEs.

### Stage C — Why might an organization choose a different CVSS threshold?

A threshold of 7 is more conservative — it catches High-severity vulnerabilities too, improving security posture but causing more build failures and slowing development. Teams must spend more time remediating or suppressing findings. A threshold of 10 is more permissive — only the most extreme vulnerabilities block the build, allowing faster delivery but accepting more risk. The tradeoff is between security rigor and development speed. Organizations in regulated industries (finance, healthcare) tend toward lower thresholds; fast-moving startups may accept higher risk.

### Stage E.1 — Did this test pass or fail?

The initial `mvn test` run failed because integration tests (`TextbookLibraryIntegrationTests`) were included in the default test execution. The integration test requires Docker (Testcontainers) which was not accessible, causing an `IllegalState: Could not find a valid Docker environment` error. After configuring the Surefire plugin to exclude `**/*IntegrationTests.java`, `mvn test` passed successfully with 6 unit tests, 0 failures.
![Stage F](./screenshots/Stage_F2.png)

![Stage F](./screenshots/Stage_F3.png)

### Stage E.2 — Why do we exclude integration tests?

Integration tests are excluded from the default `mvn test` phase because they typically require external services (databases, Docker containers) to be running, take longer to execute, and can be unreliable across environments. By excluding them, the unit test stage runs fast and only tests isolated units of code. Integration tests are then run separately in a dedicated stage with proper handling via `catchError`.

### Stage F.1 — Did this test pass or fail?

The integration test (`mvn test -Pintegration-tests`) failed with the error: `TextbookLibraryIntegrationTests » IllegalState Could not find a valid Docker environment`. This was expected because Testcontainers requires Docker to be accessible, and the Jenkins agent environment did not have Docker configured for Testcontainers.

### Stage F.3 — What is the role of a Maven profile in managing integration tests?

A Maven profile is a set of configuration overrides activated on demand. For integration tests, it overrides the Surefire plugin configuration to include only integration test classes (`**/*IntegrationTests.java`). This means `mvn test` runs unit tests by default, and `mvn test -Pintegration-tests` runs integration tests specifically. Profiles provide flexible control over which tests execute without duplicating configuration.

### Stage F.3 — Why are integration tests separated from unit tests in CI pipelines?

Unit tests are fast (milliseconds), have no external dependencies (use mocks), and are highly reliable. Integration tests are slower (seconds to minutes), require real external services (databases, APIs), and are less reliable due to network issues or environment differences. Separating them provides fast feedback from unit tests first, then runs integration tests as a separate quality gate.

### Stage F.3 — Why might the integration test have failed?

The integration tests use Testcontainers for MongoDB, which requires Docker to be running and accessible. In the Jenkins agent environment, Docker was available for building images but not configured for Testcontainers to spin up test containers. In production CI, this would be resolved using Docker-in-Docker (DinD) or by running integration tests on agents with full Docker support.

### Stage G — If a coverage stage is marked UNSTABLE, what are the causes?

The coverage stage can be marked UNSTABLE for several reasons: 
(1) JaCoCo coverage thresholds are not met. 
(2) The `jacoco:report` goal fails because no execution data file (`jacoco.exec`) was found, which happens if the `prepare-agent` goal was not run during tests or tests were skipped. 
(3) The SonarQube Quality Gate fails on coverage. The `catchError` wrapper ensures these issues are flagged but don't block the rest of the pipeline.

### Stage H — SonarQube Results
![Stage H](./screenshots/Stage_H2.png)

SonarQube analysis completed successfully with the following results:
- **Quality Gate:** Passed
- **Security:** 0 open issues (Rating A)
- **Reliability:** 1 open issue (Rating C)
- **Maintainability:** 8 open issues (Rating A)
- **Coverage:** 73.5% on 68 lines to cover
- **Duplications:** 0.0% on 378 lines
- **Security Hotspots:** 3 (Rating E)

---

## Challenges (Task 4)

### 1. OWASP Critical Vulnerability Blocking Build
**Problem:** The OWASP Dependency-Check scan failed the build due to critical CVEs in `tomcat-embed-core-10.1.43.jar` (CVE-2025-66614, CVSS 9.1 and CVE-2025-55754, CVSS 9.6).  
**Resolution:** Overrode the Tomcat version in `pom.xml` by adding `<tomcat.version>10.1.52</tomcat.version>` to the properties section, pulling in the patched release.
![Stage C](./screenshots/Stage_C3.png)

### 2. Integration Tests Failing Due to Docker/Testcontainers
**Problem:** Integration tests used Testcontainers for MongoDB, which required Docker to be accessible from the test JVM. Jenkins could run Docker commands but Testcontainers could not connect to the Docker daemon.  
**Resolution:** Wrapped the integration test stage in `catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE')` to allow the pipeline to continue while flagging the issue.
![Stage F](./screenshots/Stage_F3.png)

### 3. Docker Command Not Found in Jenkins
**Problem:** Jenkins on macOS could not find the `docker` command because `/usr/local/bin` was not in Jenkins' default PATH.  
**Resolution:** Added an `environment` block to the Jenkinsfile: `PATH = "/usr/local/bin:${env.PATH}"`.
![Docker Build & Push](./screenshots/Docker_2.png)

### 4. Docker Image Platform Mismatch
**Problem:** Docker images built on Apple Silicon (ARM64) could not run on AWS EC2 (x86_64/amd64), causing `no matching manifest for linux/amd64` errors.  
**Resolution:** Changed the Docker build command to use `docker buildx build --platform linux/amd64` for cross-platform image building.

### 5. Deprecated Docker Base Image
**Problem:** The initial Dockerfile used `openjdk:17-jre-slim` which no longer exists on Docker Hub (Oracle deprecated the official OpenJDK images).  
**Resolution:** Switched to `eclipse-temurin:17-jre`, which is the recommended community-maintained JDK distribution.
![Docker Build & Push](./screenshots/Docker_3.png)

### 6. SonarQube Authentication Failure
**Problem:** After refactoring to use Jenkins credentials, the SonarQube stage failed with HTTP 401 because the token stored in credentials was incorrect.  
**Resolution:** Regenerated the SonarQube project token and updated the Jenkins credential with the correct value.
![Stage H](./screenshots/Stage_H3.png)

### 7. Terraform Provider Binary Too Large for GitHub
**Problem:** The Terraform AWS provider binary (~648 MB) exceeded GitHub's 100 MB file size limit, blocking `git push`.  
**Resolution:** Added `.terraform/`, `*.tfstate`, and `terraform.tfvars` to `.gitignore`, removed the cached files from git tracking with `git rm -r --cached`, and force-pushed.
![Terraform](./screenshots/Terraform.png)

### 8. SSH Key Permissions on macOS
**Problem:** The EC2 `.pem` key file had overly permissive permissions (0644), causing SSH to reject it.  
**Resolution:** Set correct permissions with `chmod 400` on the key file.

### 9. MongoDB Not Available on EC2
**Problem:** The deployed application on EC2 could not fully respond because MongoDB was not provisioned on the server.  
**Status:** Documented as a known limitation. In production, MongoDB would be deployed separately (e.g., Amazon DocumentDB or Docker Compose).

---

## Repository Structure

```
├── Jenkinsfile              # Jenkins Declarative Pipeline
├── Dockerfile               # Docker image definition
├── pom.xml                  # Maven configuration with Surefire, JaCoCo, profiles
├── README.md                # This documentation
├── terraform/
│   ├── main.tf              # AWS EC2 + Security Group resources
│   ├── variables.tf         # Terraform variables
│   └── outputs.tf           # Public IP and DNS outputs
├── src/
│   ├── main/                # Application source code
│   └── test/                # Unit and integration tests
└── screenshots/             # Evidence screenshots for submission
```