# DevOps-U2

Contenedorizacion y despliegue automatizado en aws con docker y github actions
## Colaboradores
- bjscripta
    - Benjamin Candia 
- Matip9902
    - Matias Imil

## Requisitos 
- Docker desktop
- Git
- VS code
- AWS CLI 
- AWS academy con cuenta activa con laboratorio learner lab


| Componente | Tecnología | Descripción |
|------------|------------|-------------|
| **Frontend** | React + Vite + Nginx | Aplicación cliente, sirve archivos estáticos |
| **Backend** | Spring Boot 3.4.4 | API REST para lógica de negocio |
| **Base de Datos** | MySQL 8.0 en EC2 | Almacenamiento persistente |
| **Orquestación** | AWS ECS Fargate | Ejecuta contenedores sin gestionar servidores |
| **Registro de Imágenes** | AWS ECR | Almacena imágenes Docker privadas |
| **Balanceo de Carga** | AWS ALB | Expone el frontend a internet |
| **Logs** | AWS CloudWatch | Centraliza logs de contenedores |
| **Infraestructura** | Terraform | Infraestructura como Código (IaC) |


## 📁 Estructura del Proyecto
DevOps-U2/
├── backend/
│ ├── Springboot-API-REST-DESPACHO/
│ │ ├── Dockerfile
│ │ ├── entrypoint.sh
│ │ ├── pom.xml
│ │ └── src/
│ └── Springboot-API-REST-VENTAS/
│ ├── Dockerfile
│ ├── entrypoint.sh
│ ├── pom.xml
│ └── src/
├── front_despacho/
│ ├── Dockerfile
│ ├── nginx.conf
│ ├── package.json
│ ├── vite.config.js
│ └── src/
├── infra/ # Terraform
│ ├── ec2.tf
│ ├── ecr.tf
│ ├── ecs.tf
│ ├── outputs.tf
│ ├── provider.tf
│ ├── security-groups.tf
│ ├── subredes.tf
│ ├── variables.tf
│ ├── vpc.tf
│ └── terraform.tfvars
├── docker-compose.yml
└── README.md

## ¿Qué despliega este proyecto?

Módulo network: Crea VPC, subred pública y privada, Internet Gateway, NAT Gateway, Security Groups

Módulo compute: Despliega ECS Fargate para frontend (React + Nginx) y backend (Spring Boot), una EC2 con MySQL en Docker, y un Application Load Balancer para exponer el frontend.

Soporte multi-entorno: Variables y outputs configurados mediante terraform.tfvars para diferentes entornos (dev, staging, prod).    

## Despliegue

git clone <repositorio>
cd DevOps-U2

# Configurar credenciales AWS
aws configure

cambiar configuracion aws en secrets de github


# Terraform

E:disk/DevOps-U2/infra

cd infra
terraform init
terraform apply 

# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "NOMBRE-ECR.COM"

# CI/CD

git status
git add .
git commit -m "ALGO" - git commit --allow-empty -m "ALGO"
git commit origin main/deploy/feature/frontend

## Dockerfiles

# Backend

FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml .                  
COPY src ./src                   
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jdk AS runner
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
COPY entrypoint.sh /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]

# Frontend

FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm install --include=dev
COPY . .
RUN npm run build

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

