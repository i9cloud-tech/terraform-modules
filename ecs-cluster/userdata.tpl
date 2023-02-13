#!/bin/bash
# The cluster this agent should check into.
echo 'ECS_CLUSTER=${cluster_name}' >> /etc/ecs/ecs.config
# Disable privileged containers.
echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config