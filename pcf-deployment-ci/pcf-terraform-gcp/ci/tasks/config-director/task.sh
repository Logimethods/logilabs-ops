#!/bin/bash

set -eu

echo "iaas_configuration"

iaas_configuration=$(
  jq -n \
    --arg gcp_project "$GCP_PROJECT_ID" \
    --arg default_deployment_tag "$GCP_RESOURCE_PREFIX" \
    --arg auth_json "$GCP_SERVICE_ACCOUNT_KEY" \
    '
    {
      "project": $gcp_project,
      "default_deployment_tag": $default_deployment_tag,
      "auth_json": $auth_json
    }
    '
)

echo $iaas_configuration


availability_zones="${GCP_ZONE_1},${GCP_ZONE_2},${GCP_ZONE_3}"

az_configuration=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    '
    {
      "availability_zones": ($availability_zones | split(",") | map({name: .}))
    }'
)

echo "availability_zones"
echo $az_configuration

network_configuration=$(
  jq -n \
    --argjson icmp_checks_enabled false \
    --arg infra_network_name "infrastructure" \
    --arg infra_vcenter_network "${GCP_RESOURCE_PREFIX}-pcf-network/${GCP_RESOURCE_PREFIX}-mnagement-subnet/${GCP_REGION}" \
    --arg infra_network_cidr "10.0.0.0/24" \
    --arg infra_reserved_ip_ranges "10.0.0.1-10.0.0.9" \
    --arg infra_dns "10.0.0.1,8.8.8.8" \
    --arg infra_gateway "192.168.101.1" \
    --arg infra_availability_zones "$availability_zones" \
    --arg deployment_network_name "ert" \
    --arg deployment_vcenter_network "${GCP_RESOURCE_PREFIX}-virt-net/${GCP_RESOURCE_PREFIX}-subnet-ert-${GCP_REGION}/${GCP_REGION}" \
    --arg deployment_network_cidr "192.168.16.0/22" \
    --arg deployment_reserved_ip_ranges "192.168.16.1-192.168.16.9" \
    --arg deployment_dns "192.168.16.1,8.8.8.8" \
    --arg deployment_gateway "192.168.16.1" \
    --arg deployment_availability_zones "$availability_zones" \
    --argjson services_network_is_service_network true \
    --arg services_network_name "services-1" \
    --arg services_vcenter_network "${GCP_RESOURCE_PREFIX}-virt-net/${GCP_RESOURCE_PREFIX}-subnet-services-1-${GCP_REGION}/${GCP_REGION}" \
    --arg services_network_cidr "192.168.20.0/22" \
    --arg services_reserved_ip_ranges "192.168.20.1-192.168.20.9" \
    --arg services_dns "192.168.20.1,8.8.8.8" \
    --arg services_gateway "192.168.20.1" \
    --arg services_availability_zones "$availability_zones" \
    '
    {
      "icmp_checks_enabled": $icmp_checks_enabled,
      "networks": [
        {
          "name": $infra_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $infra_vcenter_network,
              "cidr": $infra_network_cidr,
              "reserved_ip_ranges": $infra_reserved_ip_ranges,
              "dns": $infra_dns,
              "gateway": $infra_gateway,
              "availability_zones": ($infra_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $deployment_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $deployment_vcenter_network,
              "cidr": $deployment_network_cidr,
              "reserved_ip_ranges": $deployment_reserved_ip_ranges,
              "dns": $deployment_dns,
              "gateway": $deployment_gateway,
              "availability_zones": ($deployment_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $services_network_name,
          "service_network": $services_network_is_service_network,
          "subnets": [
            {
              "iaas_identifier": $services_vcenter_network,
              "cidr": $services_network_cidr,
              "reserved_ip_ranges": $services_reserved_ip_ranges,
              "dns": $services_dns,
              "gateway": $services_gateway,
              "availability_zones": ($services_availability_zones | split(","))
            }
          ]
        }
      ]
    }'
)

echo "network_configuration"
echo $network_configuration

director_config=$(cat <<-EOF
{
  "ntp_servers_string": "0.pool.ntp.org",
  "resurrector_enabled": true,
  "retry_bosh_deploys": true,
  "database_type": "internal",
  "blobstore_type": "local"
}
EOF
)

echo "director_config"
echo $director_config
resource_configuration=$(cat <<-EOF
{
  "director": {
    "internet_connected": false
  },
  "compilation": {
    "internet_connected": false
  }
}
EOF
)

echo "resource_configuration"
echo $resource_configuration

security_configuration=$(
  jq -n \
    --arg trusted_certificates "$OPS_MGR_TRUSTED_CERTS" \
    '
    {
      "trusted_certificates": $trusted_certificates,
      "vm_password_type": "generate"
    }'
)

echo "security_configuration"
echo $security_configuration

network_assignment=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    --arg network "infrastructure" \
    '
    {
      "singleton_availability_zone": ($availability_zones | split(",") | .[0]),
      "network": $network
    }'
)

echo "network_assignment"
echo $network_assignment

echo "Configuring IaaS and Director..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  configure-bosh \
  --iaas-configuration "$iaas_configuration" 

 
  
#   --director-configuration "$director_config" \
#  --az-configuration "$az_configuration" \
#  --networks-configuration "$network_configuration"  
#   --iaas-configuration "$iaas_configuration" \
#--security-configuration "$security_configuration" \
#--resource-configuration "$resource_configuration" \
# --networks-configuration "$network_configuration" \
# --network-assignment "$network_assignment" 
