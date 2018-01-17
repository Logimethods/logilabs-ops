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
    --arg infra_network_name "pcf-meetup-pcf-network" \
    --arg infra_vcenter_network "${GCP_RESOURCE_PREFIX}-pcf-network/${GCP_RESOURCE_PREFIX}-mnagement-subnet/${GCP_REGION}" \
    --arg infra_network_cidr "10.0.0.0/24" \
    --arg infra_reserved_ip_ranges "10.0.0.1-10.0.0.9" \
    --arg infra_dns "10.0.0.1,8.8.8.8" \
    --arg infra_gateway "10.0.0.1" \
    --arg infra_availability_zones "$availability_zones" \
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
    --arg network "pcf-meetup-pcf-network" \
    '
    {
      "singleton_availability_zone": ($availability_zones | split(",") | .[0]),
      "network": $network
    }'
)

echo "changemark"
echo $network_assignment

echo "Configuring IaaS and Director..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  configure-bosh \
  --iaas-configuration "$iaas_configuration" \
  --director-configuration "$director_config" \
  --az-configuration "$az_configuration" \
  --networks-configuration "$network_configuration" \
  --network-assignment "$network_assignment" \
  --resource-configuration "$resource_configuration"
  
#   --iaas-configuration "$iaas_configuration" \
#--security-configuration "$security_configuration" \
#--resource-configuration "$resource_configuration" \
# --networks-configuration "$network_configuration" \
# --network-assignment "$network_assignment" 
