#!/bin/bash
set -euo pipefail

# Smoke test for the CloudFront realtime-log -> Kinesis pipeline.
# Generates a handful of requests against a venue's /data path, waits for
# CloudFront to flush realtime logs, then checks whether the Kinesis stream
# saw incoming records in that window.
#
# Usage:
#   AWS_PROFILE=<profile> ./smoke-test-realtime-stream.sh <dev|test|prod> [request_count]
#
# Env overrides:
#   KINESIS_STREAM_NAME  (default: pds-o11y-cloudfront-streaming-kinesis)
#   POLL_SECONDS          (default: 15 — delay between CloudWatch polls)
#   MAX_ATTEMPTS           (default: 12 — ~3 min total, CloudWatch metrics lag
#                            the actual event by a minute or more)

VENUE="${1:?Usage: $0 <dev|test|prod> [request_count]}"
REQUEST_COUNT="${2:-5}"
KINESIS_STREAM_NAME="${KINESIS_STREAM_NAME:-pds-o11y-cloudfront-streaming-kinesis}"
POLL_SECONDS="${POLL_SECONDS:-15}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-12}"

case "$VENUE" in
  dev)  BASE_URL="https://pds-sit.mcp.nasa.gov/data/" ;;
  test) BASE_URL="https://pds-uat.mcp.nasa.gov/data/" ;;
  prod) BASE_URL="https://pds.mcp.nasa.gov/data/" ;;
  *)
    echo "Unknown venue: $VENUE (expected dev, test, or prod)" >&2
    exit 1
    ;;
esac

TEST_START=$(python3 -c 'from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc)-timedelta(minutes=1)).strftime("%Y-%m-%dT%H:%M:%SZ"))')

echo "== Generating $REQUEST_COUNT request(s) against $BASE_URL =="
for i in $(seq 1 "$REQUEST_COUNT"); do
  curl -s -o /dev/null -w "  [$i] %{http_code} %{url_effective}\n" \
    "${BASE_URL}?smoketest=$(date +%s)-$i"
done

echo "== Polling $KINESIS_STREAM_NAME IncomingRecords since $TEST_START =="
echo "   (CloudWatch metrics lag the actual event, so this may take a few minutes)"
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  END=$(python3 -c 'from datetime import datetime, timezone; print(datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))')

  RESULT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/Kinesis \
    --metric-name IncomingRecords \
    --dimensions Name=StreamName,Value="$KINESIS_STREAM_NAME" \
    --start-time "$TEST_START" \
    --end-time "$END" \
    --period 60 \
    --statistics Sum \
    --query "sort_by(Datapoints,&Timestamp)" \
    --output json)

  TOTAL=$(python3 -c "import json,sys; print(sum(p['Sum'] for p in json.loads(sys.argv[1])))" "$RESULT")

  if python3 -c "import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)" "$TOTAL"; then
    echo "$RESULT"
    echo "PASS: $TOTAL record(s) reached the Kinesis stream (attempt $attempt/$MAX_ATTEMPTS)."

    echo "INFO: Firehose delivers to OpenSearch after a ~60s buffer delay."
    echo "      Verify ingestion via the OpenSearch UI — the domain is VPC-only"
    echo "      and not reachable from the deployment machine."

    exit 0
  fi

  echo "  [$attempt/$MAX_ATTEMPTS] no records yet, waiting ${POLL_SECONDS}s..."
  sleep "$POLL_SECONDS"
done

echo "FAIL: no records reached the Kinesis stream after $((MAX_ATTEMPTS * POLL_SECONDS))s."
exit 1
