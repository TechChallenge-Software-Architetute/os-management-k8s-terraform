# os-management-k8s-terraform

Owns the **shared network (VPC) + EKS cluster** for the OS Management platform, one
environment per branch:

| Branch | Environment | AWS account | State key |
|---|---|---|---|
| `develop` | dev | dev account | `k8s/develop/terraform.tfstate` |
| `main` | prod | prod account | `k8s/main/terraform.tfstate` |

## Architecture

```mermaid
flowchart TB
    subgraph AWS["AWS us-east-1 (per branch: develop=dev, main=prod)"]
        subgraph VPC["VPC (terraform-aws-modules/vpc)"]
            pub[Public subnets]
            priv[Private subnets]
        end
        subgraph EKS["EKS Cluster (terraform-aws-modules/eks)"]
            ng[Managed node group]
            addons["Addons: coredns, kube-proxy, vpc-cni"]
            ms[metrics-server (Helm)]
        end
        pub --> EKS
        priv --> EKS
    end

    consumers["Consumers via terraform_remote_state:<br/>os-management-database, os-management-lambda, os-management"]
    EKS -.outputs.-> consumers
```

This repository owns only the shared network and cluster — it does **not**
deploy the application, the database, or the Lambda functions. Those live in
their own repositories and read this stack's outputs (`vpc_id`,
`private_subnet_ids`, `node_security_group_id`, `cluster_name`) via
`terraform_remote_state`.

## What it creates
- VPC (public + private subnets, single NAT by default) via `terraform-aws-modules/vpc`.
- EKS cluster + managed node group via `terraform-aws-modules/eks`, with `coredns`,
  `kube-proxy`, `vpc-cni` addons.
- `metrics-server` (Helm) — the cluster prerequisite for the app's HPA. The HPA manifest
  itself lives in the app repo (`os-management`).

## Consumed by (via `terraform_remote_state`)
- **os-management-database** → `private_subnet_ids`, `node_security_group_id`, `vpc_id`.
- **os-management-lambda** → `private_subnet_ids`, `node_security_group_id`.
- **os-management** (app) → `cluster_name` (for `aws eks update-kubeconfig`).

## Outputs
`vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `node_security_group_id`,
`cluster_name`, `cluster_endpoint`, `cluster_ca_certificate` (sensitive), `region`.

## Configuration
Shared AWS auth/account/state-bucket come from **org-level secrets**, suffixed by
branch (`*_MAIN` / `*_DEVELOP`); `AWS_REGION` is a single org-level secret shared by
both branches (no suffix). See the app repo's `DEPENDENCIES.md` §5 for the full matrix.

## Local use
```bash
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init -backend=false                  # validation only (no remote state)
terraform validate
```
Real applies run in CI (`.github/workflows/cd.yml`) on pushes to `develop`/`main`.

## Notes

- Remember to add the **`soat-architecture`** user to this repository (Tech
  Challenge delivery requirement).
