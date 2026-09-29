#!/usr/bin/env bash
# Checks that a deployed site serves exactly the page of the deployed commit over HTTPS,
# and redirects HTTP to HTTPS.
# Usage: smoke-test.sh <https-url> <expected-sha256>
set -euo pipefail

readonly usage="usage: smoke-test.sh <https-url> <expected-sha256>"
readonly url="${1:?$usage}"
readonly expected_sha256="${2:?$usage}"

# On a first deployment, a new load balancer takes minutes to answer at the edge and a new
# managed certificate up to 20 minutes to become active. Later deployments answer at once.
readonly connect_retry_attempts=40
readonly connect_retry_delay_seconds=30

# The edge revalidates the page on every request, so a stale page can only come from the last
# requests to a backend that is being replaced; a short grace period absorbs them.
readonly content_check_attempts=6
readonly content_check_delay_seconds=10

readonly permanent_redirect_status=301

if [[ ! "$expected_sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "FAIL: '$expected_sha256' is not a SHA-256 hash" >&2
  exit 1
fi

# The hash is computed on the raw bytes: a shell variable would drop trailing newlines.
served_sha256() {
  curl --fail --silent --show-error \
    --retry "$connect_retry_attempts" --retry-delay "$connect_retry_delay_seconds" --retry-all-errors \
    "$url" | openssl dgst -sha256 -r | cut -d' ' -f1
}

actual_sha256=""
for ((attempt = 1; attempt <= content_check_attempts; attempt++)); do
  actual_sha256="$(served_sha256)"
  if [[ "$actual_sha256" == "$expected_sha256" ]]; then
    break
  fi
  if ((attempt < content_check_attempts)); then
    sleep "$content_check_delay_seconds"
  fi
done

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "FAIL: $url serves content $actual_sha256 instead of the deployed $expected_sha256" >&2
  exit 1
fi

http_url="http://${url#https://}"
status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$http_url")"

if [[ "$status" != "$permanent_redirect_status" ]]; then
  echo "FAIL: $http_url answered $status instead of $permanent_redirect_status" >&2
  exit 1
fi

echo "OK: $url serves the deployed page (sha256 $expected_sha256) and $http_url redirects to HTTPS"
