import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateSegment {
  CreateSegment(audience_id: String, name: String)
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Segment {
  Segment(
    id: String,
    object: String,
    name: String,
    audience_id: String,
    created_at: String,
  )
}

pub type SegmentListItem {
  SegmentListItem(
    id: String,
    name: String,
    audience_id: Option(String),
    created_at: String,
  )
}

pub type ListSegmentsResponse {
  ListSegmentsResponse(
    object: String,
    has_more: Bool,
    data: List(SegmentListItem),
  )
}

/// Builds the JSON payload for creating a segment.
pub fn create_request_body(payload: CreateSegment) -> json.Json {
  let CreateSegment(audience_id:, name:) = payload
  json.object([
    types.string_field("audience_id", audience_id),
    types.string_field("name", name),
  ])
}

/// Creates a segment in the payload's audience.
pub fn create(
  client: glesend.Client,
  payload: CreateSegment,
) -> Result(MutationResponse, http.Error) {
  let CreateSegment(audience_id:, ..) = payload
  http.post_decoded(
    client,
    http.path_join(["audiences", audience_id, "segments"]),
    create_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Lists segments for an audience using the given pagination settings.
pub fn list(
  client: glesend.Client,
  audience_id: String,
  pagination: types.Pagination,
) -> Result(ListSegmentsResponse, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "segments"]),
    types.pagination_query(pagination),
    list_segments_response_decoder(),
  )
}

/// Fetches a segment by audience and segment identifier.
pub fn get(
  client: glesend.Client,
  audience_id: String,
  segment_id: String,
) -> Result(Segment, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "segments", segment_id]),
    [],
    segment_decoder(),
  )
}

/// Deletes a segment by audience and segment identifier.
pub fn delete(
  client: glesend.Client,
  audience_id: String,
  segment_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["audiences", audience_id, "segments", segment_id]),
    delete_response_decoder(),
  )
}

/// Decodes a mutation response with id and object fields.
pub fn mutation_response_decoder() -> decode.Decoder(MutationResponse) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    decode.success(MutationResponse(id: id, object: object))
  }
}

/// Decodes a delete response.
pub fn delete_response_decoder() -> decode.Decoder(DeleteResponse) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use deleted <- decode.field("deleted", decode.bool)
    decode.success(DeleteResponse(id: id, object: object, deleted: deleted))
  }
}

/// Decodes a segment resource.
pub fn segment_decoder() -> decode.Decoder(Segment) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use name <- decode.field("name", decode.string)
    use audience_id <- decode.field("audience_id", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(Segment(
      id: id,
      object: object,
      name: name,
      audience_id: audience_id,
      created_at: created_at,
    ))
  }
}

/// Decodes a segment list item.
pub fn segment_list_item_decoder() -> decode.Decoder(SegmentListItem) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use audience_id <- decode.field(
      "audience_id",
      decode.optional(decode.string),
    )
    use created_at <- decode.field("created_at", decode.string)
    decode.success(SegmentListItem(
      id: id,
      name: name,
      audience_id: audience_id,
      created_at: created_at,
    ))
  }
}

/// Decodes a paginated segments list response.
pub fn list_segments_response_decoder() -> decode.Decoder(ListSegmentsResponse) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: segment_list_item_decoder()),
    )
    decode.success(ListSegmentsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
