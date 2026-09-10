import os
from typing import List, Optional

from google.api_core.client_options import ClientOptions
from google.cloud import discoveryengine_v1 as discoveryengine

from app.models.scan import ThreatIntelMatch


class VertexSearchNotConfigured(RuntimeError):
    pass


def _config() -> tuple[str, str, str, str]:
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT", "").strip()
    location = os.getenv("VERTEX_SEARCH_LOCATION", "global").strip() or "global"
    data_store_id = os.getenv("VERTEX_SEARCH_DATA_STORE_ID", "").strip()
    serving_config_id = os.getenv("VERTEX_SEARCH_SERVING_CONFIG", "default_serving_config").strip()
    if not project_id or not data_store_id:
        raise VertexSearchNotConfigured(
            "GOOGLE_CLOUD_PROJECT and VERTEX_SEARCH_DATA_STORE_ID are required"
        )
    return project_id, location, data_store_id, serving_config_id


def search_vertex_threat_intelligence(query: str, limit: int = 3) -> List[ThreatIntelMatch]:
    """Retrieve grounded threat-intelligence records from Vertex AI Search.

    The data store is expected to contain provenance metadata such as title,
    category, source_name, source_url, summary, and publication_date. This function
    performs retrieval only; generation remains a separate concern.
    """
    project_id, location, data_store_id, serving_config_id = _config()
    client_options: Optional[ClientOptions] = None
    if location != "global":
        client_options = ClientOptions(api_endpoint=f"{location}-discoveryengine.googleapis.com")

    client = discoveryengine.SearchServiceClient(client_options=client_options)
    serving_config = (
        f"projects/{project_id}/locations/{location}/collections/default_collection/"
        f"dataStores/{data_store_id}/servingConfigs/{serving_config_id}"
    )
    request = discoveryengine.SearchRequest(
        serving_config=serving_config,
        query=query,
        page_size=max(1, min(limit, 10)),
    )

    matches: List[ThreatIntelMatch] = []
    for result in client.search(request=request):
        document = result.document
        fields = dict(document.struct_data) if document.struct_data else {}
        source_url = str(fields.get("source_url") or fields.get("uri") or "")
        if not source_url:
            # Provenance is mandatory in ShieldScan; silently dropping an unsourced
            # search hit is safer than presenting it as verified intelligence.
            continue
        matches.append(
            ThreatIntelMatch(
                id=str(document.id),
                title=str(fields.get("title") or document.id),
                category=str(fields.get("category") or "fraud-advisory"),
                source_name=str(fields.get("source_name") or "Indexed source"),
                source_url=source_url,
                matched_terms=[],
                summary=str(fields.get("summary") or ""),
                retrieval_method="vertex-ai-search-v1",
            )
        )
        if len(matches) >= limit:
            break
    return matches
