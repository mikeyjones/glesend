import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateWebhook {
  CreateWebhook(
    url: String,
    enabled: Bool,
    events: List(String),
    description: Option(String),
  )
}

pub type UpdateWebhook {
  UpdateWebhook(
    url: Option(String),
    enabled: Option(Bool),
    events: Option(List(String)),
    description: Option(String),
  )
}

pub type CreateWebhookResponse {
  CreateWebhookResponse(object: String, id: String, signing_secret: String)
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Webhook {
  Webhook(
    object: String,
    id: String,
    endpoint: String,
    events: List(String),
    status: String,
    created_at: String,
    signing_secret: String,
  )
}

pub type WebhookListItem {
  WebhookListItem(
    id: String,
    endpoint: String,
    events: List(String),
    status: String,
    created_at: String,
  )
}

pub type ListWebhooksResponse {
  ListWebhooksResponse(
    object: String,
    has_more: Bool,
    data: List(WebhookListItem),
  )
}

/// Builds the JSON payload for creating a webhook.
pub fn create_request_body(payload: CreateWebhook) -> json.Json {
  let CreateWebhook(url:, enabled:, events:, description:) = payload
  []
  |> types.optional_string_field("description", description)
  |> types.prepend(#("events", json.array(events, of: json.string)))
  |> types.prepend(types.bool_field("enabled", enabled))
  |> types.prepend(types.string_field("url", url))
  |> json.object
}

/// Builds the JSON payload for updating a webhook.
pub fn update_request_body(payload: UpdateWebhook) -> json.Json {
  let UpdateWebhook(url:, enabled:, events:, description:) = payload
  let fields = []
  let fields = types.optional_string_field(fields, "description", description)
  let fields = case events {
    option.Some(events) -> [
      #("events", json.array(events, of: json.string)),
      ..fields
    ]
    option.None -> fields
  }
  let fields = types.optional_bool_field(fields, "enabled", enabled)
  let fields = types.optional_string_field(fields, "url", url)
  json.object(fields)
}

/// Creates a webhook.
pub fn create(
  client: glesend.Client,
  payload: CreateWebhook,
) -> Result(CreateWebhookResponse, http.Error) {
  http.post_decoded(
    client,
    "/webhooks",
    create_request_body(payload),
    create_webhook_response_decoder(),
  )
}

/// Lists webhooks using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListWebhooksResponse, http.Error) {
  http.get_decoded(
    client,
    "/webhooks",
    types.pagination_query(pagination),
    list_webhooks_response_decoder(),
  )
}

/// Fetches a webhook by its identifier.
pub fn get(
  client: glesend.Client,
  webhook_id: String,
) -> Result(Webhook, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["webhooks", webhook_id]),
    [],
    webhook_decoder(),
  )
}

/// Updates a webhook with the provided fields.
pub fn update(
  client: glesend.Client,
  webhook_id: String,
  payload: UpdateWebhook,
) -> Result(MutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["webhooks", webhook_id]),
    update_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Deletes a webhook by its identifier.
pub fn delete(
  client: glesend.Client,
  webhook_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["webhooks", webhook_id]),
    delete_response_decoder(),
  )
}

/// Decodes a create webhook response with signing secret.
pub fn create_webhook_response_decoder() -> decode.Decoder(
  CreateWebhookResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use signing_secret <- decode.field("signing_secret", decode.string)
    decode.success(CreateWebhookResponse(
      object: object,
      id: id,
      signing_secret: signing_secret,
    ))
  }
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

/// Decodes a full webhook resource.
pub fn webhook_decoder() -> decode.Decoder(Webhook) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use endpoint <- decode.field("endpoint", decode.string)
    use events <- decode.field("events", decode.list(decode.string))
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use signing_secret <- decode.field("signing_secret", decode.string)
    decode.success(Webhook(
      object: object,
      id: id,
      endpoint: endpoint,
      events: events,
      status: status,
      created_at: created_at,
      signing_secret: signing_secret,
    ))
  }
}

/// Decodes a webhook list item.
pub fn webhook_list_item_decoder() -> decode.Decoder(WebhookListItem) {
  {
    use id <- decode.field("id", decode.string)
    use endpoint <- decode.field("endpoint", decode.string)
    use events <- decode.field("events", decode.list(decode.string))
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(WebhookListItem(
      id: id,
      endpoint: endpoint,
      events: events,
      status: status,
      created_at: created_at,
    ))
  }
}

/// Decodes a paginated webhooks list response.
pub fn list_webhooks_response_decoder() -> decode.Decoder(ListWebhooksResponse) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: webhook_list_item_decoder()),
    )
    decode.success(ListWebhooksResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
