import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateBroadcast {
  CreateBroadcast(
    audience_id: String,
    from: String,
    subject: String,
    reply_to: Option(String),
    name: Option(String),
  )
}

pub type UpdateBroadcast {
  UpdateBroadcast(
    name: Option(String),
    subject: Option(String),
    reply_to: Option(String),
  )
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Broadcast {
  Broadcast(
    id: String,
    name: String,
    audience_id: Option(String),
    segment_id: Option(String),
    from: String,
    subject: String,
    reply_to: List(String),
    preview_text: String,
    status: String,
    created_at: String,
    scheduled_at: Option(String),
    sent_at: Option(String),
    html: Option(String),
    text: Option(String),
    topic_id: Option(String),
  )
}

pub type BroadcastListItem {
  BroadcastListItem(
    id: String,
    name: String,
    status: String,
    created_at: String,
    scheduled_at: Option(String),
    sent_at: Option(String),
  )
}

pub type ListBroadcastsResponse {
  ListBroadcastsResponse(
    object: String,
    has_more: Bool,
    data: List(BroadcastListItem),
  )
}

/// Builds the JSON payload for creating a broadcast.
pub fn create_request_body(payload: CreateBroadcast) -> json.Json {
  let CreateBroadcast(audience_id:, from:, subject:, reply_to:, name:) = payload
  []
  |> types.optional_string_field("name", name)
  |> types.optional_string_field("reply_to", reply_to)
  |> types.prepend(types.string_field("subject", subject))
  |> types.prepend(types.string_field("from", from))
  |> types.prepend(types.string_field("audience_id", audience_id))
  |> json.object
}

/// Builds the JSON payload for updating a broadcast.
pub fn update_request_body(payload: UpdateBroadcast) -> json.Json {
  let UpdateBroadcast(name:, subject:, reply_to:) = payload
  []
  |> types.optional_string_field("reply_to", reply_to)
  |> types.optional_string_field("subject", subject)
  |> types.optional_string_field("name", name)
  |> json.object
}

/// Creates a broadcast.
pub fn create(
  client: glesend.Client,
  payload: CreateBroadcast,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    "/broadcasts",
    create_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Lists broadcasts using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListBroadcastsResponse, http.Error) {
  http.get_decoded(
    client,
    "/broadcasts",
    types.pagination_query(pagination),
    list_broadcasts_response_decoder(),
  )
}

/// Fetches a broadcast by its identifier.
pub fn get(
  client: glesend.Client,
  broadcast_id: String,
) -> Result(Broadcast, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["broadcasts", broadcast_id]),
    [],
    broadcast_decoder(),
  )
}

/// Updates a broadcast with the provided fields.
pub fn update(
  client: glesend.Client,
  broadcast_id: String,
  payload: UpdateBroadcast,
) -> Result(MutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["broadcasts", broadcast_id]),
    update_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Deletes a broadcast by its identifier.
pub fn delete(
  client: glesend.Client,
  broadcast_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["broadcasts", broadcast_id]),
    delete_response_decoder(),
  )
}

/// Sends a broadcast immediately.
pub fn send(
  client: glesend.Client,
  broadcast_id: String,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    http.path_join(["broadcasts", broadcast_id, "send"]),
    json.object([]),
    mutation_response_decoder(),
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

/// Decodes a full broadcast resource.
pub fn broadcast_decoder() -> decode.Decoder(Broadcast) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use audience_id <- decode.field(
      "audience_id",
      decode.optional(decode.string),
    )
    use segment_id <- decode.field("segment_id", decode.optional(decode.string))
    use from <- decode.field("from", decode.string)
    use subject <- decode.field("subject", decode.string)
    use reply_to <- decode.field("reply_to", decode.list(decode.string))
    use preview_text <- decode.field("preview_text", decode.string)
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use scheduled_at <- decode.field(
      "scheduled_at",
      decode.optional(decode.string),
    )
    use sent_at <- decode.field("sent_at", decode.optional(decode.string))
    use html <- decode.field("html", decode.optional(decode.string))
    use text <- decode.field("text", decode.optional(decode.string))
    use topic_id <- decode.field("topic_id", decode.optional(decode.string))
    decode.success(Broadcast(
      id: id,
      name: name,
      audience_id: audience_id,
      segment_id: segment_id,
      from: from,
      subject: subject,
      reply_to: reply_to,
      preview_text: preview_text,
      status: status,
      created_at: created_at,
      scheduled_at: scheduled_at,
      sent_at: sent_at,
      html: html,
      text: text,
      topic_id: topic_id,
    ))
  }
}

/// Decodes a broadcast list item.
pub fn broadcast_list_item_decoder() -> decode.Decoder(BroadcastListItem) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use scheduled_at <- decode.field(
      "scheduled_at",
      decode.optional(decode.string),
    )
    use sent_at <- decode.field("sent_at", decode.optional(decode.string))
    decode.success(BroadcastListItem(
      id: id,
      name: name,
      status: status,
      created_at: created_at,
      scheduled_at: scheduled_at,
      sent_at: sent_at,
    ))
  }
}

/// Decodes a paginated broadcasts list response.
pub fn list_broadcasts_response_decoder() -> decode.Decoder(
  ListBroadcastsResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: broadcast_list_item_decoder()),
    )
    decode.success(ListBroadcastsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
