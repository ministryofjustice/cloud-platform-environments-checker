#!/bin/sh

set -euo pipefail

curl -H "X-API-KEY: ${HOODAW_API_KEY}" -d "$(./bin/cp_hosted_namespaces.rb)" ${HOODAW_HOST}/hosted_services