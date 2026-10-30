#!/usr/bin/env python3
"""Generate OpenSearch UI saved objects (export.ndjson) for the streaming index.

Builds one index pattern, the visualizations, and two dashboards:

- "CloudFront Streaming - Delivery Health": traffic, errors, latency, cache.
- "CloudFront Streaming - Data Usage": downloads by data area, mission,
  collection, file type, country, and client.

Object IDs are deterministic (uuid5 of the title), so re-importing with
overwrite=true updates objects in place instead of duplicating them.

Field names assume the index's default dynamic mapping: string fields are
`text` with a `.keyword` subfield. If an index template maps those strings as
`keyword` directly, run with `--keyword-suffix ""`.

Usage:
    python3 build_export.py                     # writes ./export.ndjson
    python3 build_export.py --output /path/x.ndjson
"""

import argparse
import json
import uuid
from pathlib import Path

NAMESPACE = uuid.UUID("6f1b7a4e-2c1d-4c5e-9a57-5d3c0a1f0b11")
INDEX_PATTERN_TITLE = "pds-o11y-cloudfront-streaming-index-*"
INDEX_PATTERN_ID = str(uuid.uuid5(NAMESPACE, "index-pattern:" + INDEX_PATTERN_TITLE))
INDEX_REF = "kibanaSavedObjectMeta.searchSourceJSON.index"
PANEL_VERSION = "3.8.0"

# request_outcome is a status: fixed colors, same in every panel.
OUTCOME_COLORS = {
    "success": "#54B399",
    "redirect": "#6092C0",
    "client_error": "#D6BF57",
    "server_error": "#E7664C",
}

KW = ".keyword"


def kw(field):
    """Return the aggregatable name of a string field."""
    return field + KW


def obj_id(kind, title):
    return str(uuid.uuid5(NAMESPACE, f"{kind}:{title}"))


# ---------------------------------------------------------------- aggs


def count(label="Requests", agg_id="1"):
    return {"id": agg_id, "enabled": True, "type": "count", "schema": "metric",
            "params": {"customLabel": label}}


def metric(agg_type, field, label, agg_id, **extra):
    params = {"field": field, "customLabel": label}
    params.update(extra)
    return {"id": agg_id, "enabled": True, "type": agg_type, "schema": "metric",
            "params": params}


def terms(field, agg_id, schema, size=10, order_by="1", other=False, label=None):
    params = {"field": field, "orderBy": order_by, "order": "desc", "size": size,
              "otherBucket": other, "otherBucketLabel": "Other",
              "missingBucket": False, "missingBucketLabel": "Missing"}
    if label:
        params["customLabel"] = label
    return {"id": agg_id, "enabled": True, "type": "terms", "schema": schema,
            "params": params}


def date_histogram(agg_id="2"):
    return {"id": agg_id, "enabled": True, "type": "date_histogram", "schema": "segment",
            "params": {"field": "@timestamp", "useNormalizedOpenSearchInterval": True,
                       "scaleMetricValues": False, "interval": "auto",
                       "drop_partials": False, "min_doc_count": 1, "extended_bounds": {}}}


# ---------------------------------------------------------------- vis params


def xy_params(chart_type, series, y_title, mode="normal", percentage=False):
    """Params for line / area / histogram with one value axis."""
    return {
        "type": chart_type,
        "grid": {"categoryLines": False, "valueAxis": "ValueAxis-1"},
        "categoryAxes": [{"id": "CategoryAxis-1", "type": "category", "position": "bottom",
                          "show": True, "style": {}, "scale": {"type": "linear"},
                          "labels": {"show": True, "filter": True, "truncate": 100},
                          "title": {}}],
        "valueAxes": [{"id": "ValueAxis-1", "name": "LeftAxis-1", "type": "value",
                       "position": "left", "show": True, "style": {},
                       "scale": {"type": "linear",
                                 "mode": "percentage" if percentage else "normal"},
                       "labels": {"show": True, "rotate": 0, "filter": False, "truncate": 100},
                       "title": {"text": y_title}}],
        "seriesParams": [{"show": True, "type": t, "mode": mode,
                          "data": {"label": label, "id": agg_id},
                          "valueAxis": "ValueAxis-1", "drawLinesBetweenPoints": True,
                          "lineWidth": 2, "interpolate": "linear", "showCircles": False}
                         for agg_id, label, t in series],
        "addTooltip": True, "addLegend": True, "legendPosition": "right",
        "times": [], "addTimeMarker": False, "labels": {},
        "thresholdLine": {"show": False, "value": 10, "width": 1, "style": "full",
                          "color": "#E7664C"},
    }


def hbar_params(y_title):
    params = xy_params("histogram", [("1", y_title, "histogram")], y_title)
    params["type"] = "histogram"
    params["categoryAxes"][0]["position"] = "left"
    params["categoryAxes"][0]["labels"]["truncate"] = 200
    params["valueAxes"][0]["position"] = "bottom"
    params["valueAxes"][0]["labels"]["rotate"] = 75
    params["legendPosition"] = "right"
    params["addLegend"] = False
    return params


TABLE_PARAMS = {"perPage": 10, "showPartialRows": False, "showMetricsAtAllLevels": False,
                "showTotal": False, "totalFunc": "sum", "percentageCol": ""}

PIE_PARAMS = {"type": "pie", "addTooltip": True, "addLegend": True,
              "legendPosition": "right", "isDonut": True,
              "labels": {"show": False, "values": True, "last_level": True,
                         "truncate": 100}}

METRIC_PARAMS = {"addTooltip": True, "addLegend": False, "type": "metric",
                 "metric": {"percentageMode": False, "useRanges": False,
                            "colorSchema": "Green to Red", "metricColorMode": "None",
                            "colorsRange": [{"from": 0, "to": 10000}],
                            "labels": {"show": True}, "invertColors": False,
                            "style": {"bgFill": "#000", "bgColor": False,
                                      "labelColor": False, "subText": "",
                                      "fontSize": 36}}}


# ---------------------------------------------------------------- objects


def search_source(query="", with_index=True):
    source = {"query": {"query": query, "language": "kuery"}, "filter": []}
    if with_index:
        source["indexRefName"] = INDEX_REF
    return json.dumps(source)


def visualization(title, vis_type, aggs, params, query="", description="",
                  ui_state=None):
    vis_state = {"title": title, "type": vis_type, "aggs": aggs, "params": params}
    return {
        "id": obj_id("visualization", title),
        "type": "visualization",
        "migrationVersion": {"visualization": "7.10.0"},
        "attributes": {
            "title": title,
            "description": description,
            "version": 1,
            "uiStateJSON": json.dumps(ui_state or {}),
            "visState": json.dumps(vis_state),
            "kibanaSavedObjectMeta": {"searchSourceJSON": search_source(query)},
        },
        "references": [{"id": INDEX_PATTERN_ID, "name": INDEX_REF, "type": "index-pattern"}],
    }


def controls(title, fields):
    control_list = []
    references = []
    for i, (field, label) in enumerate(fields):
        ref_name = f"control_{i}_index_pattern"
        control_list.append({
            "id": str(i + 1), "fieldName": field, "parent": "", "label": label,
            "type": "list", "indexPatternRefName": ref_name,
            "options": {"type": "terms", "multiselect": True, "dynamicOptions": True,
                        "size": 50, "order": "desc"},
        })
        references.append({"id": INDEX_PATTERN_ID, "name": ref_name, "type": "index-pattern"})
    vis_state = {"title": title, "type": "input_control_vis", "aggs": [],
                 "params": {"controls": control_list, "updateFiltersOnChange": True,
                            "useTimeFilter": True, "pinFilters": False}}
    return {
        "id": obj_id("visualization", title),
        "type": "visualization",
        "migrationVersion": {"visualization": "7.10.0"},
        "attributes": {
            "title": title, "description": "", "version": 1, "uiStateJSON": "{}",
            "visState": json.dumps(vis_state),
            "kibanaSavedObjectMeta": {"searchSourceJSON": search_source(with_index=False)},
        },
        "references": references,
    }


def dashboard(title, description, layout, time_from, refresh_ms):
    """layout: list of (visualization_object, x, y, w, h). Grid is 48 wide."""
    panels = []
    references = []
    for i, (vis, x, y, w, h) in enumerate(layout):
        panel_id = str(i + 1)
        panels.append({"version": PANEL_VERSION, "panelIndex": panel_id,
                       "gridData": {"x": x, "y": y, "w": w, "h": h, "i": panel_id},
                       "embeddableConfig": {}, "panelRefName": f"panel_{i}"})
        references.append({"id": vis["id"], "name": f"panel_{i}", "type": "visualization"})
    return {
        "id": obj_id("dashboard", title),
        "type": "dashboard",
        "migrationVersion": {"dashboard": "7.9.3"},
        "attributes": {
            "title": title, "description": description, "hits": 0, "version": 1,
            "timeRestore": True, "timeFrom": time_from, "timeTo": "now",
            "refreshInterval": {"pause": refresh_ms == 0, "value": refresh_ms},
            "optionsJSON": json.dumps({"hidePanelTitles": False, "useMargins": True}),
            "panelsJSON": json.dumps(panels),
            "kibanaSavedObjectMeta": {"searchSourceJSON": json.dumps(
                {"query": {"query": "", "language": "kuery"}, "filter": []})},
        },
        "references": references,
    }


def index_pattern():
    field_formats = {
        "sc-bytes": {"id": "bytes"},
        "time-to-first-byte": {"id": "number", "params": {"pattern": "0.000"}},
        "sc-status": {"id": "number", "params": {"pattern": "0"}},
    }
    return {
        "id": INDEX_PATTERN_ID,
        "type": "index-pattern",
        "migrationVersion": {"index-pattern": "7.6.0"},
        "attributes": {
            "title": INDEX_PATTERN_TITLE,
            "timeFieldName": "@timestamp",
            # Empty field list: OpenSearch UI reads the fields from the mapping on first load.
            "fields": "[]",
            "fieldFormatMap": json.dumps(field_formats),
        },
        "references": [],
    }


# ---------------------------------------------------------------- dashboards


def delivery_health():
    outcome = kw("request_outcome")
    q_5xx = f'{outcome}:"server_error"'
    q_4xx = f'{outcome}:"client_error"'
    outcome_ui = {"vis": {"colors": OUTCOME_COLORS}}

    traffic = visualization(
        "Streaming - Traffic summary", "metric",
        [count("Requests"),
         metric("sum", "sc-bytes", "Data served", "2"),
         metric("cardinality", kw("c-ip"), "Unique client IPs (approx.)", "3")],
        METRIC_PARAMS)
    errors_5xx = visualization(
        "Streaming - Server errors (5xx)", "metric", [count("Server errors (5xx)")],
        METRIC_PARAMS, query=q_5xx)
    errors_4xx = visualization(
        "Streaming - Client errors (4xx)", "metric", [count("Client errors (4xx)")],
        METRIC_PARAMS, query=q_4xx)
    ttfb_p95 = visualization(
        "Streaming - Time to first byte p95 (s)", "metric",
        [metric("percentiles", "time-to-first-byte", "TTFB p95 (s)", "1",
                percents=[95])],
        METRIC_PARAMS)

    by_outcome = visualization(
        "Streaming - Requests over time by outcome", "histogram",
        [count(), date_histogram(),
         terms(outcome, "3", "group", size=4, order_by="1")],
        xy_params("histogram", [("1", "Requests", "histogram")], "Requests",
                  mode="stacked"),
        ui_state=outcome_ui)
    outcome_mix = visualization(
        "Streaming - Outcome mix over time (%)", "area",
        [count(), date_histogram(),
         terms(outcome, "3", "group", size=4, order_by="1")],
        xy_params("area", [("1", "Requests", "area")], "Share of requests",
                  mode="stacked", percentage=True),
        ui_state=outcome_ui)

    ttfb = visualization(
        "Streaming - Time to first byte percentiles (s)", "line",
        [metric("percentiles", "time-to-first-byte", "TTFB (s)", "1",
                percents=[50, 95, 99]),
         date_histogram()],
        xy_params("line", [("1", "TTFB (s)", "line")], "Seconds"))
    cache = visualization(
        "Streaming - Edge result type over time", "area",
        [count(), date_histogram(),
         terms(kw("x-edge-result-type"), "3", "group", size=6, other=True)],
        xy_params("area", [("1", "Requests", "area")], "Share of requests",
                  mode="stacked", percentage=True),
        description="Hit, RefreshHit, Miss, Error, etc. Hit share is the CloudFront cache hit ratio.")

    status_table = visualization(
        "Streaming - Status codes", "table",
        [count(), terms("sc-status", "2", "bucket", size=20, label="Status")],
        TABLE_PARAMS)
    edge_result = visualization(
        "Streaming - Edge response result type", "pie",
        [count(), terms(kw("x-edge-response-result-type"), "2", "segment", size=8,
                        other=True)],
        PIE_PARAMS)
    edge_locations = visualization(
        "Streaming - Top edge locations", "table",
        [count(),
         terms(kw("x-edge-location"), "2", "bucket", size=20, label="Edge location"),
         metric("percentiles", "time-to-first-byte", "TTFB p95 (s)", "3", percents=[95])],
        TABLE_PARAMS)

    paths_5xx = visualization(
        "Streaming - Top paths with server errors (5xx)", "table",
        [count(),
         terms(kw("cs-uri-stem"), "2", "bucket", size=20, label="Path"),
         terms("sc-status", "3", "bucket", size=3, label="Status")],
        TABLE_PARAMS, query=q_5xx)
    paths_4xx = visualization(
        "Streaming - Top paths with client errors (4xx)", "table",
        [count(),
         terms(kw("cs-uri-stem"), "2", "bucket", size=20, label="Path"),
         terms("sc-status", "3", "bucket", size=3, label="Status")],
        TABLE_PARAMS, query=q_4xx)

    layout = [
        (traffic, 0, 0, 24, 8), (errors_5xx, 24, 0, 8, 8),
        (errors_4xx, 32, 0, 8, 8), (ttfb_p95, 40, 0, 8, 8),
        (by_outcome, 0, 8, 24, 15), (outcome_mix, 24, 8, 24, 15),
        (ttfb, 0, 23, 24, 15), (cache, 24, 23, 24, 15),
        (status_table, 0, 38, 16, 16), (edge_result, 16, 38, 16, 16),
        (edge_locations, 32, 38, 16, 16),
        (paths_5xx, 0, 54, 24, 18), (paths_4xx, 24, 54, 24, 18),
    ]
    dash = dashboard(
        "CloudFront Streaming - Delivery Health",
        "Real-time CloudFront delivery health for PDS /data paths: traffic, errors, "
        "latency, and cache behavior.",
        layout, "now-24h", 60000)
    return [v for v, *_ in layout] + [dash]


def data_usage():
    q_dl = "is_download:true"
    q_dir = f'{kw("request_type")}:"directory_listing"'
    bytes_dl = "Data downloaded"

    filters = controls("Streaming - Usage filters", [
        (kw("data_area"), "Data area"),
        (kw("mission"), "Mission"),
        (kw("collection"), "Collection"),
        (kw("request_type"), "Request type"),
        (kw("c-country"), "Country"),
    ])
    downloads_kpi = visualization(
        "Streaming - Download summary", "metric",
        [count("Downloads"),
         metric("sum", "sc-bytes", bytes_dl, "2"),
         metric("cardinality", kw("c-ip"), "Unique downloaders (approx.)", "3")],
        METRIC_PARAMS, query=q_dl,
        description="Downloads are successful GET responses with bytes for data, "
                    "metadata, or other file requests (is_download).")
    listings_kpi = visualization(
        "Streaming - Directory listings", "metric", [count("Directory listings")],
        METRIC_PARAMS, query=q_dir)

    volume = visualization(
        "Streaming - Data downloaded over time by data area", "histogram",
        [metric("sum", "sc-bytes", bytes_dl, "1"), date_histogram(),
         terms(kw("data_area"), "3", "group", size=8, other=True)],
        xy_params("histogram", [("1", bytes_dl, "histogram")], bytes_dl, mode="stacked"),
        query=q_dl)
    request_mix = visualization(
        "Streaming - Request type mix", "pie",
        [count(), terms(kw("request_type"), "2", "segment", size=6)],
        PIE_PARAMS)

    missions = visualization(
        "Streaming - Top missions by data downloaded", "horizontal_bar",
        [metric("sum", "sc-bytes", bytes_dl, "1"),
         terms(kw("mission"), "2", "segment", size=15)],
        hbar_params(bytes_dl), query=q_dl)
    collections = visualization(
        "Streaming - Top collections", "table",
        [count("Downloads"),
         terms(kw("collection"), "2", "bucket", size=25, label="Collection"),
         metric("sum", "sc-bytes", bytes_dl, "3"),
         metric("cardinality", kw("c-ip"), "Unique IPs", "4")],
        TABLE_PARAMS, query=q_dl)

    file_types = visualization(
        "Streaming - Downloads by file type", "table",
        [count("Downloads"),
         terms(kw("file_extension"), "2", "bucket", size=20, label="Extension"),
         metric("sum", "sc-bytes", bytes_dl, "3")],
        TABLE_PARAMS, query=q_dl)
    countries = visualization(
        "Streaming - Top countries", "table",
        [count("Downloads"),
         terms(kw("c-country"), "2", "bucket", size=20, label="Country"),
         metric("sum", "sc-bytes", bytes_dl, "3"),
         metric("cardinality", kw("c-ip"), "Unique IPs", "4")],
        TABLE_PARAMS, query=q_dl)
    referrers = visualization(
        "Streaming - Top referrers", "table",
        [count("Requests"),
         terms(kw("cs-referer"), "2", "bucket", size=20, label="Referrer")],
        TABLE_PARAMS, query="cs-referer:*")

    files = visualization(
        "Streaming - Top downloaded files", "table",
        [count("Downloads"),
         terms(kw("cs-uri-stem"), "2", "bucket", size=25, label="Path"),
         metric("sum", "sc-bytes", bytes_dl, "3"),
         metric("cardinality", kw("c-ip"), "Unique IPs", "4")],
        TABLE_PARAMS, query=q_dl)
    directories = visualization(
        "Streaming - Top browsed directories", "table",
        [count("Listings"),
         terms(kw("path_prefix"), "2", "bucket", size=25, label="Prefix"),
         metric("cardinality", kw("c-ip"), "Unique IPs", "3")],
        TABLE_PARAMS, query=q_dir)

    user_agents = visualization(
        "Streaming - Top user agents", "table",
        [count("Requests"),
         terms(kw("cs-user-agent"), "2", "bucket", size=20, label="User agent"),
         metric("sum", "sc-bytes", "Data served", "3")],
        TABLE_PARAMS)
    clients = visualization(
        "Streaming - Top clients by data downloaded", "table",
        [metric("sum", "sc-bytes", bytes_dl, "1"),
         terms(kw("c-ip"), "2", "bucket", size=20, label="Client IP"),
         count("Downloads", agg_id="3"),
         terms(kw("c-country"), "4", "bucket", size=1, label="Country")],
        TABLE_PARAMS, query=q_dl)

    layout = [
        (filters, 0, 0, 48, 6),
        (downloads_kpi, 0, 6, 32, 8), (listings_kpi, 32, 6, 16, 8),
        (volume, 0, 14, 32, 15), (request_mix, 32, 14, 16, 15),
        (missions, 0, 29, 24, 18), (collections, 24, 29, 24, 18),
        (file_types, 0, 47, 16, 17), (countries, 16, 47, 16, 17),
        (referrers, 32, 47, 16, 17),
        (files, 0, 64, 24, 18), (directories, 24, 64, 24, 18),
        (user_agents, 0, 82, 24, 17), (clients, 24, 82, 24, 17),
    ]
    dash = dashboard(
        "CloudFront Streaming - Data Usage",
        "What PDS data is being downloaded and browsed: data areas, missions, "
        "collections, file types, countries, and clients.",
        layout, "now-7d", 0)
    return [v for v, *_ in layout] + [dash]


def main():
    global KW
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parent / "export.ndjson")
    parser.add_argument("--keyword-suffix", default=".keyword",
                        help='Suffix for aggregatable string fields (default ".keyword")')
    args = parser.parse_args()
    KW = args.keyword_suffix

    objects = [index_pattern()] + delivery_health() + data_usage()
    with args.output.open("w", encoding="utf-8") as out:
        for obj in objects:
            out.write(json.dumps(obj, separators=(",", ":")) + "\n")
    print(f"Wrote {len(objects)} saved objects to {args.output}")


if __name__ == "__main__":
    main()
