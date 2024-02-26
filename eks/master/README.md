# EKS Cluster

This configs will launch a new EKS cluster, without any node

**Terraform Workspaces**

This config will have only one bucket for any environment needed,  
it will be handled by terraform workspaces

```
terraform workspaces select < dev | hmg | prod >
```
