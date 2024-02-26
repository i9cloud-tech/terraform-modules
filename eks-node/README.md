# EKS-Node TF Module

This module launches EKS worker nodes

### Main resources

- Autoscaling group (AG)
- EC2 from AG
- Profile policy to EC2 instances access grants
- Security Groups (SG) configurando acesso ao cluster e ao EFS
- Security Groups (SG) granting cluster and EFS
- Elastic File System (EFS), mounted in `/mnt/efs/` directory

### How to use

```hcl
module "dev_tools_node" {
  source  = "./eks-node"

  cluster = {
    ca       = <eks certificate authority>
    name     = <eks cluster name>
    endpoint = <eks cluster endpoint>
    sg_id    = <eks cluster security group id>
  }
  node_name            = <node name>
  ssh_key_name         = <ssh_key_name>
  instance_types       = <lista de instance_types>
  vpc_id               = <vpc_id>
  vpc_cidr_block       = <vpc cidr_block>
  private_subnets      = <subnets privadas>
  public_subnets       = <subnets publicas>
  autoscale_configs    = {
    desired_capacity              = <quantidade de instacias desejado>
    min_size                      = <min de instancias desejado>
    max_size                      = <max de instancias desejado>
    on_demand_base_capacity       = <min de instancias ondemand>
    on_demand_percentage_capacity = <% de instancias ondemand>
  }
}
```
