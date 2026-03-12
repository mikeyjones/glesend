import gleam/dynamic/decode
import gleam/json
import glesend
import glesend/http
import glesend/types

pub type CreateAudience {
  CreateAudience(name: String)
}

pub type CreateAudienceResponse {
  CreateAudienceResponse(id: String, object: String, name: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Audience {
  Audience(id: String, object: String, name: String, created_at: String)
}

pub type ListAudiencesResponse {
  ListAudiencesResponse(object: String, data: List(Audience))
}

/// Builds the JSON payload for creating an audience.
pub fn create_request_body(payload: CreateAudience) -> json.Json {
  let CreateAudience(name:) = payload
  json.object([types.string_field("name", name)])
}

/// Creates an audience.
pub fn create(
  client: glesend.Client,
  payload: CreateAudience,
) -> Result(CreateAudienceResponse, http.Error) {
  http.post_decoded(
    client,
    "/audiences",
    create_request_body(payload),
    create_audience_response_decoder(),
  )
}

/// Lists audiences using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListAudiencesResponse, http.Error) {
  http.get_decoded(
    client,
    "/audiences",
    types.pagination_query(pagination),
    list_audiences_response_decoder(),
  )
}

/// Fetches an audience by its identifier.
pub fn get(
  client: glesend.Client,
  audience_id: String,
) -> Result(Audience, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id]),
    [],
    audience_decoder(),
  )
}

/// Deletes an audience by its identifier.
pub fn delete(
  client: glesend.Client,
  audience_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["audiences", audience_id]),
    delete_response_decoder(),
  )
}

/// Decodes a create audience response.
pub fn create_audience_response_decoder() -> decode.Decoder(
  CreateAudienceResponse,
) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use name <- decode.field("name", decode.string)
    decode.success(CreateAudienceResponse(id: id, object: object, name: name))
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

/// Decodes an audience resource.
pub fn audience_decoder() -> decode.Decoder(Audience) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use name <- decode.field("name", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(Audience(
      id: id,
      object: object,
      name: name,
      created_at: created_at,
    ))
  }
}

/// Decodes an audiences list response.
pub fn list_audiences_response_decoder() -> decode.Decoder(
  ListAudiencesResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use data <- decode.field("data", decode.list(of: audience_decoder()))
    decode.success(ListAudiencesResponse(object: object, data: data))
  }
}
