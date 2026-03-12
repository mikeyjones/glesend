import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/result
import glesend
import glesend/http
import glesend/types

pub type CreateApiKey {
  CreateApiKey(
    name: String,
    permission: Option(String),
    domain_id: Option(String),
  )
}

pub type CreateApiKeyResponse {
  CreateApiKeyResponse(id: String, token: String)
}

pub type ApiKeyListItem {
  ApiKeyListItem(id: String, name: String, created_at: String)
}

pub type ListApiKeysResponse {
  ListApiKeysResponse(object: String, data: List(ApiKeyListItem))
}

/// Builds the JSON payload for creating an API key.
pub fn create_request_body(payload: CreateApiKey) -> json.Json {
  let CreateApiKey(name:, permission:, domain_id:) = payload
  []
  |> types.optional_string_field("domain_id", domain_id)
  |> types.optional_string_field("permission", permission)
  |> types.prepend(types.string_field("name", name))
  |> json.object
}

/// Creates an API key.
pub fn create(
  client: glesend.Client,
  payload: CreateApiKey,
) -> Result(CreateApiKeyResponse, http.Error) {
  http.post_decoded(
    client,
    "/api-keys",
    create_request_body(payload),
    create_api_key_response_decoder(),
  )
}

/// Lists API keys using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListApiKeysResponse, http.Error) {
  http.get_decoded(
    client,
    "/api-keys",
    types.pagination_query(pagination),
    list_api_keys_response_decoder(),
  )
}

/// Deletes an API key by its identifier.
pub fn delete(
  client: glesend.Client,
  api_key_id: String,
) -> Result(Nil, http.Error) {
  http.delete(client, http.path_join(["api-keys", api_key_id]))
  |> result.replace(Nil)
}

/// Decodes a create API key response.
pub fn create_api_key_response_decoder() -> decode.Decoder(CreateApiKeyResponse) {
  {
    use id <- decode.field("id", decode.string)
    use token <- decode.field("token", decode.string)
    decode.success(CreateApiKeyResponse(id: id, token: token))
  }
}

/// Decodes an API key list item.
pub fn api_key_list_item_decoder() -> decode.Decoder(ApiKeyListItem) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(ApiKeyListItem(id: id, name: name, created_at: created_at))
  }
}

/// Decodes an API keys list response.
pub fn list_api_keys_response_decoder() -> decode.Decoder(ListApiKeysResponse) {
  {
    use object <- decode.field("object", decode.string)
    use data <- decode.field(
      "data",
      decode.list(of: api_key_list_item_decoder()),
    )
    decode.success(ListApiKeysResponse(object: object, data: data))
  }
}
