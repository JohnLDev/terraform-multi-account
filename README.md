# 🌐 Terraform Infrastructure Management

Este repositório organiza a infraestrutura de forma escalável e reutilizável usando:

- ✅ Módulos reutilizáveis
- ✅ Ambientes separados (`dev`, `prod`, etc.)
- ✅ Backend remoto por ambiente
- ✅ Validações de variáveis
- ✅ Aplicação controlada via `terraform.tfvars`

---

## 📁 Estrutura do Projeto

```
terraform/
├── modules/
│   └── function_app/            # Módulo reutilizável
│       ├── main.tf
│       ├── storage.tf
│       ├── service_plan.tf
│       ├── variables.tf
│       ├── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf              # Entrada do ambiente
│   │   ├── backend.tf           # State remoto
│   │   ├── variables.tf         # Declaração de variáveis
│   │   └── terraform.tfvars     # Valores para o ambiente dev
│   └── prod/
│       ├── ...
```

---

## 🚀 Como aplicar a infraestrutura

### 1. Acesse o ambiente desejado

```bash
cd terraform/environments/dev
```

### 2. Inicialize o Terraform

```bash
terraform init
```

### 3. Visualize o plano de execução

```bash
terraform plan -var-file="terraform.tfvars"
```

### 4. Aplique a infraestrutura

```bash
terraform apply -var-file="terraform.tfvars"
```

---

## 📦 Como funciona a estrutura

### 🔹 Módulos (`modules/`)

Contêm os recursos organizados por domínio. Por exemplo:

- `function_app/` cria Function App, Storage Account e App Service Plan.

Cada módulo é reutilizável e parametrizado com variáveis.

### 🔹 Ambientes (`environments/`)

Cada ambiente possui:

- Um `backend.tf` exclusivo para isolar o estado remoto
- Um `main.tf` que instancia os módulos com os valores apropriados
- Um `terraform.tfvars` com os valores reais usados naquele ambiente
- Um `variables.tf` com as variáveis esperadas no root daquele ambiente (se necessário)

---

## ⚙️ Variáveis e Validações

- As variáveis são declaradas no `variables.tf` dos **módulos**
- Os **valores** são definidos por ambiente usando `terraform.tfvars`
- É possível aplicar validações como:

```hcl
variable "stage" {
  type        = string
  description = "Deployment stage"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.stage)
    error_message = "Stage must be one of dev, staging or prod."
  }
}
```

---

## 🔐 Boas práticas

- ✅ Use `backend.tf` para armazenar o estado remoto e isolar por ambiente
- ✅ Mantenha `terraform.tfvars` com valores por ambiente
- ✅ Utilize validação de variáveis para garantir consistência
- ✅ Nunca compartilhe secrets diretamente em `.tfvars`; use variáveis de ambiente ou arquivos ignorados
- ✅ Use `outputs.tf` apenas para o que realmente precisa ser exposto

---

## 🧠 Dicas úteis

| Ação                         | Comando                                       |
|------------------------------|-----------------------------------------------|
| Ver outputs                  | `terraform output`                            |
| Mover recurso para módulo    | `terraform state mv ...`                      |
| Apagar recursos              | `terraform destroy -var-file=terraform.tfvars`|
| Recarregar variáveis         | `terraform refresh`                           |
| Ver arquivos de plano        | `terraform show plan.out`                     |

---

## 🧪 Exemplo de uso de módulo

```hcl
module "function_app" {
  source                       = "../../../modules/function_app"
  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  storage_account_name         = var.storage_account_name
  storage_account_access_key   = var.storage_account_access_key

  app_settings = {
    ENV = var.stage
  }
}
```

---

## 📌 Requisitos

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) ≥ 1.3
- Azure CLI autenticado (`az login`) ou Service Principal configurado
- Acesso à Storage Account para uso do backend remoto
- Permissões adequadas nos grupos de recursos e subscriptions

---

## ✅ Próximos passos (sugestões)

- 🔄 Integrar com **GitHub Actions** para aplicar automaticamente por ambiente
- 🏷️ Versionar os módulos usando Git com `?ref=v1.0.0`
- 🔐 Utilizar Azure Key Vault ou variáveis de ambiente para secrets
- 📊 Usar `terraform-docs` para documentar automaticamente os módulos

---

## 🛠️ Licença

Este projeto é distribuído sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
