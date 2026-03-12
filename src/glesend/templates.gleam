import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateTemplate {
  CreateTemplate(name: String, subject: String, html: String)
}

pub type UpdateTemplate {
  UpdateTemplate(
    name: Option(String),
    subject: Option(String),
    html: Option(String),
  )
}

pub type DuplicateTemplate {
  DuplicateTemplate(name: String)
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type Template {
  Template(
    object: String,
    id: String,
    name: String,
    subject: String,
    html: String,
    text: Option(String),
    status: String,
    created_at: String,
    updated_at: String,
  )
}

pub type TemplateListItem {
  TemplateListItem(
    id: String,
    name: String,
    status: String,
    created_at: String,
    updated_at: String,
  )
}

pub type ListTemplatesResponse {
  ListTemplatesResponse(
    object: String,
    has_more: Bool,
    data: List(TemplateListItem),
  )
}

/// Builds the JSON payload for creating a template.
pub fn create_request_body(payload: CreateTemplate) -> json.Json {
  let CreateTemplate(name:, subject:, html:) = payload
  json.object([
    types.string_field("name", name),
    types.string_field("subject", subject),
    types.string_field("html", html),
  ])
}

/// Builds the JSON payload for updating a template.
pub fn update_request_body(payload: UpdateTemplate) -> json.Json {
  let UpdateTemplate(name:, subject:, html:) = payload
  []
  |> types.optional_string_field("html", html)
  |> types.optional_string_field("subject", subject)
  |> types.optional_string_field("name", name)
  |> json.object
}

/// Builds the JSON payload for duplicating a template.
pub fn duplicate_request_body(payload: DuplicateTemplate) -> json.Json {
  let DuplicateTemplate(name:) = payload
  json.object([types.string_field("name", name)])
}

/// Creates a template.
pub fn create(
  client: glesend.Client,
  payload: CreateTemplate,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    "/templates",
    create_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Lists templates using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListTemplatesResponse, http.Error) {
  http.get_decoded(
    client,
    "/templates",
    types.pagination_query(pagination),
    list_templates_response_decoder(),
  )
}

/// Fetches a template by its identifier.
pub fn get(
  client: glesend.Client,
  template_id: String,
) -> Result(Template, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["templates", template_id]),
    [],
    template_decoder(),
  )
}

/// Updates a template with the provided fields.
pub fn update(
  client: glesend.Client,
  template_id: String,
  payload: UpdateTemplate,
) -> Result(MutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["templates", template_id]),
    update_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Deletes a template by its identifier.
pub fn delete(
  client: glesend.Client,
  template_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["templates", template_id]),
    delete_response_decoder(),
  )
}

/// Publishes a template so it can be used for sends.
pub fn publish(
  client: glesend.Client,
  template_id: String,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    http.path_join(["templates", template_id, "publish"]),
    json.object([]),
    mutation_response_decoder(),
  )
}

/// Creates a duplicate of an existing template.
pub fn duplicate(
  client: glesend.Client,
  template_id: String,
  payload: DuplicateTemplate,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    http.path_join(["templates", template_id, "duplicate"]),
    duplicate_request_body(payload),
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

/// Decodes a full template resource.
pub fn template_decoder() -> decode.Decoder(Template) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use subject <- decode.field("subject", decode.string)
    use html <- decode.field("html", decode.string)
    use text <- decode.field("text", decode.optional(decode.string))
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use updated_at <- decode.field("updated_at", decode.string)
    decode.success(Template(
      object: object,
      id: id,
      name: name,
      subject: subject,
      html: html,
      text: text,
      status: status,
      created_at: created_at,
      updated_at: updated_at,
    ))
  }
}

/// Decodes a template list item.
pub fn template_list_item_decoder() -> decode.Decoder(TemplateListItem) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use updated_at <- decode.field("updated_at", decode.string)
    decode.success(TemplateListItem(
      id: id,
      name: name,
      status: status,
      created_at: created_at,
      updated_at: updated_at,
    ))
  }
}

/// Decodes a paginated templates list response.
pub fn list_templates_response_decoder() -> decode.Decoder(
  ListTemplatesResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: template_list_item_decoder()),
    )
    decode.success(ListTemplatesResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
