import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateTopic {
  CreateTopic(name: String, audience_id: String)
}

pub type UpdateTopic {
  UpdateTopic(name: Option(String))
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Topic {
  Topic(id: String, object: String, name: String, created_at: String)
}

pub type ListTopicsResponse {
  ListTopicsResponse(object: String, has_more: Bool, data: List(Topic))
}

/// Builds the JSON payload for creating a topic.
pub fn create_request_body(payload: CreateTopic) -> json.Json {
  let CreateTopic(name:, audience_id:) = payload
  json.object([
    types.string_field("name", name),
    types.string_field("audience_id", audience_id),
  ])
}

/// Builds the JSON payload for updating a topic.
pub fn update_request_body(payload: UpdateTopic) -> json.Json {
  let UpdateTopic(name:) = payload
  []
  |> types.optional_string_field("name", name)
  |> json.object
}

/// Creates a topic in the payload's audience.
pub fn create(
  client: glesend.Client,
  payload: CreateTopic,
) -> Result(MutationResponse, http.Error) {
  let CreateTopic(audience_id:, ..) = payload
  http.post_decoded(
    client,
    http.path_join(["audiences", audience_id, "topics"]),
    create_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Lists topics for an audience using the given pagination settings.
pub fn list(
  client: glesend.Client,
  audience_id: String,
  pagination: types.Pagination,
) -> Result(ListTopicsResponse, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "topics"]),
    types.pagination_query(pagination),
    list_topics_response_decoder(),
  )
}

/// Fetches a topic by audience and topic identifier.
pub fn get(
  client: glesend.Client,
  audience_id: String,
  topic_id: String,
) -> Result(Topic, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "topics", topic_id]),
    [],
    topic_decoder(),
  )
}

/// Updates a topic with the provided fields.
pub fn update(
  client: glesend.Client,
  audience_id: String,
  topic_id: String,
  payload: UpdateTopic,
) -> Result(MutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["audiences", audience_id, "topics", topic_id]),
    update_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Deletes a topic by audience and topic identifier.
pub fn delete(
  client: glesend.Client,
  audience_id: String,
  topic_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["audiences", audience_id, "topics", topic_id]),
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

/// Decodes a topic resource.
pub fn topic_decoder() -> decode.Decoder(Topic) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use name <- decode.field("name", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(Topic(
      id: id,
      object: object,
      name: name,
      created_at: created_at,
    ))
  }
}

/// Decodes a paginated topics list response.
pub fn list_topics_response_decoder() -> decode.Decoder(ListTopicsResponse) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field("data", decode.list(of: topic_decoder()))
    decode.success(ListTopicsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
