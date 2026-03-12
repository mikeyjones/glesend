import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateContactProperty {
  CreateContactProperty(name: String, property_type: String)
}

pub type UpdateContactProperty {
  UpdateContactProperty(name: Option(String))
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type ContactProperty {
  ContactProperty(
    id: String,
    object: String,
    key: String,
    property_type: String,
    created_at: String,
  )
}

pub type ListContactPropertiesResponse {
  ListContactPropertiesResponse(
    object: String,
    has_more: Bool,
    data: List(ContactProperty),
  )
}

/// Builds the JSON payload for creating a contact property.
pub fn create_request_body(payload: CreateContactProperty) -> json.Json {
  let CreateContactProperty(name:, property_type:) = payload
  json.object([
    types.string_field("name", name),
    types.string_field("type", property_type),
  ])
}

/// Builds the JSON payload for updating a contact property.
pub fn update_request_body(payload: UpdateContactProperty) -> json.Json {
  let UpdateContactProperty(name:) = payload
  []
  |> types.optional_string_field("name", name)
  |> json.object
}

/// Creates a contact property.
pub fn create(
  client: glesend.Client,
  payload: CreateContactProperty,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    "/contact-properties",
    create_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Lists contact properties using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListContactPropertiesResponse, http.Error) {
  http.get_decoded(
    client,
    "/contact-properties",
    types.pagination_query(pagination),
    list_contact_properties_response_decoder(),
  )
}

/// Fetches a contact property by its identifier.
pub fn get(
  client: glesend.Client,
  property_id: String,
) -> Result(ContactProperty, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["contact-properties", property_id]),
    [],
    contact_property_decoder(),
  )
}

/// Updates a contact property.
pub fn update(
  client: glesend.Client,
  property_id: String,
  payload: UpdateContactProperty,
) -> Result(MutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["contact-properties", property_id]),
    update_request_body(payload),
    mutation_response_decoder(),
  )
}

/// Deletes a contact property by its identifier.
pub fn delete(
  client: glesend.Client,
  property_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["contact-properties", property_id]),
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

/// Decodes a contact property resource.
pub fn contact_property_decoder() -> decode.Decoder(ContactProperty) {
  {
    use id <- decode.field("id", decode.string)
    use object <- decode.field("object", decode.string)
    use key <- decode.field("key", decode.string)
    use property_type <- decode.field("type", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(ContactProperty(
      id: id,
      object: object,
      key: key,
      property_type: property_type,
      created_at: created_at,
    ))
  }
}

/// Decodes a paginated contact properties list response.
pub fn list_contact_properties_response_decoder() -> decode.Decoder(
  ListContactPropertiesResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: contact_property_decoder()),
    )
    decode.success(ListContactPropertiesResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
