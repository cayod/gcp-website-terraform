#!/usr/bin/env bash
# Checks that a deployed site serves the expected page over HTTPS and redirects HTTP to HTTPS.
# Usage: smoke-test.sh <https-url> <expected-text>
set -euo pipefail

readonly url="${1:?usage: smoke-test.sh <https-url> <expected-text>}"
readonly expected_text="${2:?usage: smoke-test.sh <https-url> <expected-text>}"

# On a first deployment, a new load balancer takes minutes to answer at the edge and a new
# managed certificate up to 20 minutes to become active. Later deployments answer at once.
readonly retry_attempts=40
readonly retry_delay_seconds=30
readonly permanent_redirect_status=301

body="$(curl --fail --silent --show-error \
  --retry "$retry_attempts" --retry-delay "$retry_delay_seconds" --retry-all-errors \
  "$url")"

if ! grep --quiet --fixed-strings "$expected_text" <<<"$body"; then
  echo "FAIL: $url does not contain '$expected_text'" >&2
  exit 1
fi

http_url="http://${url#https://}"
status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$http_url")"

if [[ "$status" != "$permanent_redirect_status" ]]; then
  echo "FAIL: $http_url answered $status instead of $permanent_redirect_status" >&2
  exit 1
fi

echo "OK: $url serves the expected page and $http_url redirects to HTTPS"
