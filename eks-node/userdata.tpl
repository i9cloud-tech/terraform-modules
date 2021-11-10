MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
set -o xtrace
B64_CLUSTER_CA=${cluster_ca}
API_SERVER_URL=${api_url}
/etc/eks/bootstrap.sh ${cluster_name} --kubelet-extra-args \
  '--node-labels=eks.amazonaws.com/nodegroup-image=${instance_type},eks.amazonaws.com/nodegroup=${node_group_name},infra=${label}' \
  --b64-cluster-ca $B64_CLUSTER_CA \
  --apiserver-endpoint $API_SERVER_URL

if test ! -z "${efs}"; then
  sudo yum install -y amazon-efs-utils
  sudo mkdir -p /mnt/efs
  sudo pip3 install --upgrade boto3
  sudo mount -t efs ${efs}:/ /mnt/efs
fi

--//--
