#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

port="${AWSMISSIONS_PORT:-4566}"
container="awsmissions-floci"
ns="awsmissions"
[ "$port" = "4566" ] || { container="awsmissions-floci-$port"; ns="awsm$port"; }

case "${1:-}" in
  --env)
    # Usage in a second terminal:  eval "$(./play.sh --env)"
    # Points the AWS CLI at the emulator and hides real ~/.aws credentials.
    root="$(pwd)"
    mkdir -p .awsmissions
    printf '[default]\nregion = us-east-1\noutput = json\nendpoint_url = http://localhost:%s\n' "$port" > .awsmissions/aws-config
    printf '[default]\naws_access_key_id = test\naws_secret_access_key = test\n' > .awsmissions/aws-credentials
    cat <<ENV
unset AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
export AWS_CONFIG_FILE="$root/.awsmissions/aws-config"
export AWS_SHARED_CREDENTIALS_FILE="$root/.awsmissions/aws-credentials"
export AWS_ENDPOINT_URL="http://localhost:$port"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_REGION=us-east-1 AWS_PAGER=""
export AWSMISSIONS_PORT=$port AWSMISSIONS_NAMESPACE=$ns
export PS1="(awsmissions) \${PS1:-\$ }"
ENV
    exit 0
    ;;
  --stop)
    if [ -x .venv/bin/python ]; then py=.venv/bin/python; else py=python3; fi
    AWSMISSIONS_PORT="$port" "$py" -c "from engine import floci; floci.stop()"
    echo "Stopped $container and the containers it spawned."
    exit 0
    ;;
  --reset|--reset-progress)
    rm -f progress.json
    shift
    ;;
  -h|--help)
    echo "Usage: ./play.sh [--reset-progress | --env | --stop]"
    exit 0
    ;;
esac

if [ -x .venv/bin/python ]; then
  exec .venv/bin/python -m engine.engine "$@"
fi
exec python3 -m engine.engine "$@"
