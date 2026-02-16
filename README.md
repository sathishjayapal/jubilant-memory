# Jubilant Memory

A comprehensive microservices monorepo containing multiple interconnected Spring Boot services for tracking running activities, managing financial services, and integrating with fitness platforms like Garmin and Strava.

## 🏗️ Architecture Overview

This project follows a microservices architecture pattern with service discovery, centralized configuration, and event-driven communication.

### Core Services

- **accounts/** - Account management microservice
- **cards/** - Card service for managing payment cards
- **loans/** - Loan management service
- **config/** - Centralized configuration service
- **eurekaserver/** - Service discovery using Netflix Eureka

### Running & Fitness Services

- **running/** - Core running activity tracking service
- **trackgarmin/** - Garmin data synchronization and tracking
- **trackstrava/** - Strava integration and activity import
- **garmindatainitializer/** - Garmin database initialization service
- **sathishrunsinitfordb/** - Database initialization and setup

### Support Services

- **event-service/** - Event handling and processing
- **resumes/** - Resume/CV management service
- **wi-traffic/** - Wisconsin traffic analysis service
- **sathishruns-common/** - Shared utilities, DTOs, and common code

## 🛠️ Tech Stack

- **Language:** Java (Spring Boot)
- **Build Tool:** Maven (Multi-module)
- **Service Discovery:** Netflix Eureka
- **Configuration:** Spring Cloud Config
- **Database:** PostgreSQL (various services)
- **Container:** Docker & Docker Compose

## 📋 Prerequisites

- Java 17 or higher
- Maven 3.8+
- Docker & Docker Compose
- PostgreSQL (or use Docker Compose)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd jubilant-memory
```

### 2. Build All Modules

```bash
mvn clean install
```

### 3. Start Infrastructure Services

```bash
docker-compose up -d
```

This will start:
- PostgreSQL databases
- Eureka Server
- Config Server
- Message brokers (if applicable)

### 4. Run Services

Each service can be started individually:

```bash
# Start Eureka Server first
cd eurekaserver
mvn spring-boot:run

# Start Config Server
cd ../config
mvn spring-boot:run

# Start individual microservices
cd ../running
mvn spring-boot:run
```

## 📁 Module Structure

```
jubilant-memory/
├── accounts/              # Account management
├── cards/                 # Card service
├── config/                # Config server
├── eurekaserver/          # Service discovery
├── event-service/         # Event handling
├── garmindatainitializer/ # Garmin data init
├── loans/                 # Loan service
├── resumes/               # Resume service
├── running/               # Running tracking
├── sathishruns-common/    # Shared utilities
├── sathishrunsinitfordb/  # DB initialization
├── trackgarmin/           # Garmin integration
├── trackstrava/           # Strava integration
└── wi-traffic/            # Traffic analysis
```

## 🔧 Configuration

Each service has its own `application.yml` or `application.properties` file. Configuration can be centralized using the config service.

### Service Discovery

All services register with Eureka Server at: `http://localhost:8761`

### Database Configuration

Each service requiring a database should have its connection configured in `application.yml`:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/dbname
    username: ${DB_USER}
    password: ${DB_PASSWORD}
```

## 🏃 Running Activity Integration

### Garmin Integration

The `trackgarmin` service connects to Garmin Connect API to sync activities automatically.

### Strava Integration

The `trackstrava` service provides OAuth2 integration with Strava for activity import.

## 🧪 Testing

Run tests for all modules:

```bash
mvn test
```

Run tests for specific module:

```bash
cd running
mvn test
```

## 📦 Building for Production

Build Docker images for all services:

```bash
mvn clean package
docker build -t jubilant-memory/<service-name> ./<service-name>
```

## 🐳 Docker Deployment

Use Docker Compose for full stack deployment:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 📊 Monitoring

- **Eureka Dashboard:** http://localhost:8761
- **Individual Service Health:** http://localhost:{port}/actuator/health

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests
4. Submit a pull request

## 📝 License

[Add your license here]

## 👤 Author

Sathish Jayapal

---

Last Updated: February 2026
