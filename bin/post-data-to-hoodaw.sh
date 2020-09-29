#!/bin/sh

set -euo pipefail

curl -H "X-API-KEY: ${HOODAW_API_KEY}" -d "$(/app/bin/cp_hosted_namespaces.rb)" ${HOODAW_HOST}/hosted_services
