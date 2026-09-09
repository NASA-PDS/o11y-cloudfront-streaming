import base64
import binascii
import json
import re
from datetime import datetime, timezone
from pathlib import PurePosixPath
from urllib.parse import parse_qs, unquote, urlsplit


# Must exactly match the fields and ordering configured in the
# CloudFront real-time log configuration.
FIELDS = [
    "timestamp",
    "c-ip",
    "time-to-first-byte",
    "sc-status",
    "sc-bytes",
    "cs-method",
    "cs-protocol",
    "cs-host",
    "cs-uri-stem",
    "x-edge-location",
    "x-edge-request-id",
    "cs-user-agent",
    "cs-referer",
    "cs-uri-query",
    "x-edge-response-result-type",
    "x-edge-result-type",
    "c-country",
]


INTEGER_FIELDS = {
    "sc-status",
    "sc-bytes",
}

FLOAT_FIELDS = {
    "timestamp",
    "time-to-first-byte",
}


# Science/data product extensions.
DATA_EXTENSIONS = {
    "img",
    "cub",
    "csv",
    "dat",
    "bin",
    "fits",
    "fits.fz",
    "fz",
    "fit",
    "jp2",
    "tif",
    "tiff",
    "hdf",
    "hdf4",
    "hdf5",
    "h5",
    "nc",
    "nc4",
    "grb",
    "grib",
    "grib2",
    "zip",
    "gz",
    "bz2",
    "xz",
    "tab",
    "tar",
    "tar.gz",
    "tar.bz2",
    "tar.xz",
}

# Metadata/document extensions.
METADATA_EXTENSIONS = {
    "lbl",
    "cat",
    "txt",
    "xml",
    "json",
    "fmt",
    "lis",
    "md",
    "pdf",
}

# Web application/static asset extensions.
STATIC_EXTENSIONS = {
    "css",
    "js",
    "map",
    "gif",
    "png",
    "jpg",
    "jpeg",
    "svg",
    "ico",
    "woff",
    "woff2",
    "ttf",
    "eot",
}

# Check these before extracting only the final suffix.
COMPOUND_EXTENSIONS = {
    "fits.fz",
    "tar.gz",
    "tar.bz2",
    "tar.xz",
}

# Generic collection-like identifiers, for example:
#
# LROLRC_1066B
# USA_NASA_PDS_ODTGEO_200XX
#
# The identifier must:
# - contain at least one underscore,
# - contain at least one digit,
# - contain only letters, numbers, underscores, or hyphens.
COLLECTION_IDENTIFIER_PATTERN = re.compile(
    r"^(?=.*_)(?=.*\d)[A-Z0-9_-]+$"
)


def convert_value(field, value):
    """Convert CloudFront strings to appropriate JSON types."""
    if value == "-":
        return None

    try:
        if field in INTEGER_FIELDS:
            return int(value)

        if field in FLOAT_FIELDS:
            return float(value)

    except (TypeError, ValueError):
        return value

    return value


def decode_record_data(encoded_data):
    """Decode one Base64-encoded Firehose record."""
    try:
        decoded_bytes = base64.b64decode(
            encoded_data,
            validate=True,
        )
    except (binascii.Error, ValueError) as exc:
        raise ValueError(
            f"Invalid Base64 record data: {exc}"
        ) from exc

    try:
        decoded_text = decoded_bytes.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError(
            f"Record is not valid UTF-8: {exc}"
        ) from exc

    return decoded_text.rstrip("\r\n")


def parse_cloudfront_record(decoded_text):
    """Parse one tab-delimited CloudFront real-time log record."""
    values = decoded_text.split("\t")

    if len(values) != len(FIELDS):
        raise ValueError(
            f"Expected {len(FIELDS)} fields but received "
            f"{len(values)} fields"
        )

    return {
        field: convert_value(field, value)
        for field, value in zip(FIELDS, values)
    }


def create_iso_timestamp(epoch_timestamp):
    """Convert CloudFront epoch seconds to ISO-8601 UTC."""
    if not isinstance(epoch_timestamp, (int, float)):
        return None

    try:
        return (
            datetime.fromtimestamp(
                epoch_timestamp,
                tz=timezone.utc,
            )
            .isoformat(timespec="milliseconds")
            .replace("+00:00", "Z")
        )
    except (OverflowError, OSError, ValueError):
        return None


def get_path_and_query(uri_path, query_string):
    """
    Return the decoded URI path and effective query string.

    CloudFront normally separates cs-uri-stem and cs-uri-query,
    but some observed records include a query string directly
    in cs-uri-stem.
    """
    raw_uri = uri_path or ""
    effective_query = query_string or ""

    try:
        parsed_uri = urlsplit(raw_uri)
        decoded_path = unquote(parsed_uri.path)

        if not effective_query and parsed_uri.query:
            effective_query = parsed_uri.query

    except ValueError:
        decoded_path = unquote(raw_uri)

    return decoded_path, effective_query


def parse_query_parameters(uri_path, query_string):
    """Parse the effective request query parameters."""
    _, effective_query = get_path_and_query(
        uri_path,
        query_string,
    )

    if not effective_query:
        return {}

    try:
        return parse_qs(
            effective_query,
            keep_blank_values=True,
        )
    except ValueError:
        return {}


def get_file_extension(uri_path):
    """
    Extract a lowercase file extension from the actual URI path.

    Examples:
        /product.IMG       -> img
        /product.fits.fz   -> fits.fz
        /archive.tar.gz    -> tar.gz
        /main.css          -> css
        /directory/        -> None
    """
    if not uri_path:
        return None

    decoded_path, _ = get_path_and_query(
        uri_path,
        None,
    )

    file_name = PurePosixPath(decoded_path).name.lower()

    if "." not in file_name:
        return None

    for compound_extension in sorted(
        COMPOUND_EXTENSIONS,
        key=len,
        reverse=True,
    ):
        if file_name.endswith(f".{compound_extension}"):
            return compound_extension

    extension = file_name.rsplit(".", 1)[-1]

    if not extension or len(extension) > 12:
        return None

    return extension


def get_prefix_values(uri_path, query_string):
    """Return decoded prefix values from the request query."""
    query_parameters = parse_query_parameters(
        uri_path,
        query_string,
    )

    return [
        unquote(prefix).strip("/")
        for prefix in query_parameters.get("prefix", [])
        if prefix
    ]


def find_collection_identifier(path_parts):
    """
    Find a collection-like identifier in a list of path components.

    Examples:
        LROLRC_1066B
        USA_NASA_PDS_ODTGEO_200XX
    """
    for part in path_parts:
        normalized_part = part.upper()

        if COLLECTION_IDENTIFIER_PATTERN.fullmatch(
            normalized_part
        ):
            return normalized_part

    return None


def get_data_dimensions(uri_path, query_string):
    """
    Derive reusable dimensions from a /data/store/... request.

    Direct-file example:

        /data/store/img/lunar_reconnaissance_orbiter/
        pds4/lroc/lro-l-lroc-3-cdr/LROLRC_1066B/...

    Produces approximately:

        data_area = img
        mission = lunar_reconnaissance_orbiter
        collection = LROLRC_1066B

    Directory-listing example:

        /data/store/img/?prefix=
        THEMIS/PDS4/USA_NASA_PDS_ODTGEO_200XX/...

    Produces approximately:

        data_area = img
        mission = THEMIS
        collection = USA_NASA_PDS_ODTGEO_200XX
    """
    decoded_path, _ = get_path_and_query(
        uri_path,
        query_string,
    )

    path_parts = [
        part
        for part in decoded_path.split("/")
        if part
    ]

    lower_parts = [
        part.lower()
        for part in path_parts
    ]

    data_area = None
    mission = None
    collection = None
    path_prefix = None

    candidate_parts = []

    # Locate /data/store/<data-area>/...
    for index in range(len(lower_parts) - 1):
        if (
            lower_parts[index] == "data"
            and lower_parts[index + 1] == "store"
        ):
            remaining_parts = path_parts[index + 2:]

            if remaining_parts:
                data_area = remaining_parts[0].lower()

            if len(remaining_parts) > 1:
                mission = remaining_parts[1]
                candidate_parts.extend(remaining_parts[1:])

            break

    prefix_values = get_prefix_values(
        uri_path,
        query_string,
    )

    for prefix_value in prefix_values:
        prefix_parts = [
            part
            for part in prefix_value.split("/")
            if part
        ]

        if not prefix_parts:
            continue

        if mission is None:
            mission = prefix_parts[0]

        candidate_parts.extend(prefix_parts)

        if path_prefix is None:
            path_prefix = prefix_value

    collection = find_collection_identifier(
        candidate_parts
    )

    # Keep a useful generic prefix even when a formal collection
    # identifier cannot be recognized.
    if path_prefix is None and candidate_parts:
        path_prefix = "/".join(candidate_parts[:5])

    return {
        "data_area": data_area,
        "mission": mission,
        "collection": collection,
        "path_prefix": path_prefix,
    }


def classify_request(uri_path, query_string, extension):
    """
    Classify the requested resource.

    Returns:
        request_type
        is_file_request
    """
    decoded_path, _ = get_path_and_query(
        uri_path,
        query_string,
    )

    query_parameters = parse_query_parameters(
        uri_path,
        query_string,
    )

    normalized_path = decoded_path.rstrip("/").lower()

    has_directory_parameters = (
        "prefix" in query_parameters
        or "delimiter" in query_parameters
    )

    is_directory_listing = (
        normalized_path.startswith("/data/store/")
        and has_directory_parameters
    )

    if is_directory_listing:
        return "directory_listing", False

    if extension in DATA_EXTENSIONS:
        return "data_download", True

    if extension in METADATA_EXTENSIONS:
        return "metadata_download", True

    if extension in STATIC_EXTENSIONS:
        return "static_asset", False

    if extension:
        return "other_file", True

    return "other", False


def get_request_outcome(status):
    """Convert an HTTP status code into a generic outcome."""
    if not isinstance(status, int):
        return "unknown"

    if 200 <= status < 300:
        return "success"

    if 300 <= status < 400:
        return "redirect"

    if 400 <= status < 500:
        return "client_error"

    if status >= 500:
        return "server_error"

    return "other"


def add_derived_fields(document):
    """Add generic derived fields to the CloudFront document."""
    timestamp = document.get("timestamp")
    uri_path = document.get("cs-uri-stem")
    query_string = document.get("cs-uri-query")
    method = document.get("cs-method")
    status = document.get("sc-status")
    response_bytes = document.get("sc-bytes")

    file_extension = get_file_extension(uri_path)

    request_type, is_file_request = classify_request(
        uri_path,
        query_string,
        file_extension,
    )

    dimensions = get_data_dimensions(
        uri_path,
        query_string,
    )

    request_outcome = get_request_outcome(status)

    is_get_request = (
        isinstance(method, str)
        and method.upper() == "GET"
    )

    is_successful_response = (
        isinstance(status, int)
        and 200 <= status < 300
    )

    has_response_bytes = (
        isinstance(response_bytes, int)
        and response_bytes > 0
    )

    # Count a request as a download only when:
    # - it looks like a file request,
    # - it uses GET,
    # - the response is successful,
    # - and bytes were returned.
    is_download = (
        is_file_request
        and is_get_request
        and is_successful_response
        and has_response_bytes
    )

    document["@timestamp"] = create_iso_timestamp(
        timestamp
    )
    document["request_type"] = request_type
    document["request_outcome"] = request_outcome
    document["file_extension"] = file_extension
    document["is_file_request"] = is_file_request
    document["is_download"] = is_download

    document.update(dimensions)

    return document


def encode_document(document):
    """Encode one JSON document for return to Firehose."""
    json_line = (
        json.dumps(
            document,
            separators=(",", ":"),
            ensure_ascii=False,
        )
        + "\n"
    )

    return base64.b64encode(
        json_line.encode("utf-8")
    ).decode("utf-8")


def lambda_handler(event, context):
    """Transform Firehose records into newline-delimited JSON."""
    records = event.get("records", [])

    print(
        json.dumps(
            {
                "message": "Firehose transformation started",
                "recordCount": len(records),
                "awsRequestId": getattr(
                    context,
                    "aws_request_id",
                    None,
                ),
            }
        )
    )

    output = []
    successful_count = 0
    failed_count = 0

    for record in records:
        record_id = record.get("recordId")
        original_data = record.get("data")

        try:
            if not record_id:
                raise ValueError(
                    "Record is missing recordId"
                )

            if not original_data:
                raise ValueError(
                    "Record is missing data"
                )

            decoded_text = decode_record_data(
                original_data
            )

            document = parse_cloudfront_record(
                decoded_text
            )

            document = add_derived_fields(
                document
            )

            transformed_data = encode_document(
                document
            )

            output.append(
                {
                    "recordId": record_id,
                    "result": "Ok",
                    "data": transformed_data,
                }
            )

            successful_count += 1

            print(
                json.dumps(
                    {
                        "message": "Record transformed",
                        "recordId": record_id,
                        "status": document.get(
                            "sc-status"
                        ),
                        "path": document.get(
                            "cs-uri-stem"
                        ),
                        "requestType": document.get(
                            "request_type"
                        ),
                        "requestOutcome": document.get(
                            "request_outcome"
                        ),
                        "dataArea": document.get(
                            "data_area"
                        ),
                        "mission": document.get(
                            "mission"
                        ),
                        "collection": document.get(
                            "collection"
                        ),
                        "fileExtension": document.get(
                            "file_extension"
                        ),
                        "isFileRequest": document.get(
                            "is_file_request"
                        ),
                        "isDownload": document.get(
                            "is_download"
                        ),
                    },
                    default=str,
                )
            )

        except Exception as exc:
            failed_count += 1

            print(
                json.dumps(
                    {
                        "message": (
                            "Record transformation failed"
                        ),
                        "recordId": record_id,
                        "errorType": type(exc).__name__,
                        "error": str(exc),
                    }
                )
            )

            output.append(
                {
                    "recordId": record_id,
                    "result": "ProcessingFailed",
                    "data": original_data or "",
                }
            )

    print(
        json.dumps(
            {
                "message": (
                    "Firehose transformation completed"
                ),
                "totalRecords": len(records),
                "successfulRecords": successful_count,
                "failedRecords": failed_count,
            }
        )
    )

    return {"records": output}
