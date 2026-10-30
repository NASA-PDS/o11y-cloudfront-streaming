# OpenSearch UI dashboards

Saved objects for the streaming index `pds-o11y-cloudfront-streaming-index-*`:

| File | Contents |
|---|---|
| `build_export.py` | Generator (Python stdlib only). Source of truth for the panels. |
| `export.ndjson` | Generated output: 1 index pattern, 27 visualizations, 2 dashboards. |

Object IDs are derived from titles, so importing again with `overwrite=true` updates the
objects in place.

## Dashboards

**CloudFront Streaming - Delivery Health** (last 24 hours, refreshes every minute)

| Panel | Shows |
|---|---|
| Traffic summary | Requests, data served (`sc-bytes`), unique client IPs |
| Server errors (5xx), Client errors (4xx) | Error counts for the time range |
| Time to first byte p95 | Latency headline |
| Requests over time by outcome | Stacked bars by `request_outcome`, fixed status colors |
| Outcome mix over time (%) | Share of success / redirect / client_error / server_error |
| Time to first byte percentiles | p50, p95, p99 over time |
| Edge result type over time | Share of `x-edge-result-type`; the `Hit` share is the cache hit ratio |
| Status codes, Edge response result type, Top edge locations | Breakdowns, with p95 TTFB per edge location |
| Top paths with 5xx / 4xx | `cs-uri-stem` and status for failing requests |

**CloudFront Streaming - Data Usage** (last 7 days)

| Panel | Shows |
|---|---|
| Usage filters | Drop-downs for data area, mission, collection, request type, country |
| Download summary | Downloads, data downloaded, unique downloaders (`is_download:true`) |
| Directory listings | Count of `request_type:directory_listing` |
| Data downloaded over time by data area | Stacked bytes by `data_area` |
| Request type mix | Donut of `request_type` |
| Top missions by data downloaded | Horizontal bars |
| Top collections, Top downloaded files | Downloads, bytes, unique IPs |
| Downloads by file type, Top countries, Top referrers | Breakdowns |
| Top browsed directories | `path_prefix` for directory listings |
| Top user agents, Top clients by data downloaded | Who is pulling data |

Notes:

- Unique IP counts use the `cardinality` aggregation and are approximate.
- `mission` keeps the case from the URL or `prefix` parameter, so one mission can show up
  under two spellings (for example `THEMIS` and `themis`).
- String fields aggregate on their `.keyword` subfield. With the default dynamic mapping,
  that subfield skips values over 256 characters, so very long paths or user agents are
  left out of the "Top" tables.
- The index pattern formats `sc-bytes` as bytes and `time-to-first-byte` as seconds.

## Field mapping prerequisite

The panels assume the index's default dynamic mapping: string fields are `text` with a
`.keyword` subfield. Check this in OpenSearch UI **Dev Tools**:

```http
GET pds-o11y-cloudfront-streaming-index-*/_mapping/field/mission*,sc-bytes,is_download,@timestamp
```

Expect: `mission.keyword` of type `keyword`, `sc-bytes` of type `long`, `is_download` of type
`boolean`, and `@timestamp` of type `date`. If an index template maps the strings as plain
`keyword` instead, regenerate with `--keyword-suffix ""`.

## Regenerate

After changing `build_export.py`:

```bash
REPO_DIR="<path-to-this-checkout>"
python3 "${REPO_DIR}/config/opensearch-ui/build_export.py"
```

## Import with the UI

In the target workspace, open **Assets** (or **Dashboards management** > **Saved
objects**), choose **Import**, select `export.ndjson`, choose **Check for existing assets** >
**Automatically overwrite conflicts**, and select the data source named after the domain.

## Import with the API

The OpenSearch UI application exposes the Saved Objects API under each workspace, signed
with SigV4 (service `opensearch`). The calling role must be a workspace collaborator with
**Read and write** or **Admin**. Requires curl 7.75 or later and `jq`.

1. Set variables and load credentials. Copy the host and workspace ID from the browser
   URL of the workspace, which looks like
   `https://<app-host>/w/<workspace-id>/app/...`:

   ```bash
   REGION="us-west-2"
   PROFILE_NAME="<sso-profile>"
   APP_HOST="<app-host>"            # host only, no https://
   WORKSPACE_ID="<workspace-id>"
   REPO_DIR="<path-to-this-checkout>"

   eval $(aws configure export-credentials --profile "${PROFILE_NAME}" --format env)
   ```

2. Find the data source ID for the domain:

   ```bash
   curl -sS \
     "https://${APP_HOST}/w/${WORKSPACE_ID}/api/saved_objects/_find?type=data-source" \
     --aws-sigv4 "aws:amz:${REGION}:opensearch" \
     --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
     -H "x-amz-security-token: ${AWS_SESSION_TOKEN}" \
     -H "osd-xsrf: true" \
     | jq -r '.saved_objects[] | "\(.id)  \(.attributes.title)"'
   ```

   Expect: one line per data source. Pick the one named after the domain:

   ```bash
   DATA_SOURCE_ID="<data-source-id-from-above>"
   ```

3. Import:

   ```bash
   curl -sS -X POST \
     "https://${APP_HOST}/w/${WORKSPACE_ID}/api/saved_objects/_import?overwrite=true&dataSourceId=${DATA_SOURCE_ID}" \
     --aws-sigv4 "aws:amz:${REGION}:opensearch" \
     --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
     -H "x-amz-security-token: ${AWS_SESSION_TOKEN}" \
     -H "osd-xsrf: true" \
     -F "file=@${REPO_DIR}/config/opensearch-ui/export.ndjson" \
     | jq '{success, successCount, errors}'
   ```

   Expect: `"success": true` and `"successCount": 30`. OpenSearch UI appends the data source
   title to each imported title (for example
   `CloudFront Streaming - Delivery Health_<domain-name>`). The IDs stay the same, so a
   later import with `overwrite=true` updates these objects.

4. In the workspace, open **Dashboards** and choose either `CloudFront Streaming` dashboard.

**If it fails**

| Symptom | Check |
|---|---|
| `curl: (6) Could not resolve host: https` | `APP_HOST` includes `https://`; set the host only. |
| `401 Unauthorized` | The request was signed for the wrong region. Check that `echo "${REGION}"` prints the region in the app host. |
| `403` | Credentials expired (re-run step 1), or the role is not a workspace collaborator with write access. |
| `400` mentioning xsrf | The `osd-xsrf: true` header is missing. |
| `errors` lists `missing_references` | The data source ID is wrong; re-run step 2. |
| Panels show "Could not locate that index-pattern-field" | The mapping differs from the prerequisite above; regenerate with the right `--keyword-suffix`. |
| Panels are empty | No documents in the time range; run `GET _cat/indices/pds-o11y-cloudfront-streaming-index-*?v` in Dev Tools. |
