# S3 Public Exposure Watchdog (AWS + Terraform)

Detecta cuando un bucket S3 queda público con **AWS Config** y envía alertas vía **EventBridge + SNS**.
- Sprint 1: Detección + alerta.
- Sprint 2: Auto-remediación (Lambda).

## Requisitos
- AWS CLI v2 (perfil `lab`)
- Terraform >= 1.6

## Uso rápido
```bash
cd infra
terraform init
terraform apply -var="alert_email=tu@correo.com"
