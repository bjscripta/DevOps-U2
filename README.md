# DevOps-U2

**Contenedorización y despliegue automatizado en AWS con Docker y GitHub Actions**

---

## 👥 Colaboradores

| Usuario | Nombre |
|---------|--------|
| `bjscripta` | Benjamín Candia |
| `Matip9902` | Matías Imil |

---

## 📋 Requisitos

- Docker Desktop
- Git
- VS Code
- AWS CLI configurado
- Cuenta AWS Academy con laboratorio Learner Lab activo

---

## 🏗️ Tecnologías

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

```

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
├── infra/
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

```

---

## 📦 ¿Qué despliega este proyecto?

| Módulo | Recursos | Descripción |
|--------|----------|-------------|
| **Network** | VPC, subred pública/privada, IGW, NAT Gateway, Security Groups | Redes y conectividad |
| **Compute** | ECS Fargate (Frontend + Backend), EC2 MySQL, ALB | Cómputo y balanceo |
| **Registry** | ECR (2 repositorios) | Almacenamiento de imágenes Docker |

**Soporte multi-entorno:** Variables y outputs configurados mediante `terraform.tfvars` para diferentes entornos (dev, prod).

---

## Configuracion de GitHub
Ir a GitHub → Repositorio → Settings → Secrets and variables → Actions
Agregar:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_ACCOUNT_ID

## Configuracion de GitHub


```
cd infra
terraform init
```

