import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateContact {
  CreateContact(
    email: String,
    first_name: Option(String),
    last_name: Option(String),
    unsubscribed: Option(Bool),
    audience_id: String,
  )
}

pub type UpdateContact {
  UpdateContact(
    first_name: Option(String),
    last_name: Option(String),
    unsubscribed: Option(Bool),
  )
}

pub type ContactMutationResponse {
  ContactMutationResponse(object: String, id: String)
}

pub type DeleteContactResponse {
  DeleteContactResponse(object: String, id: String, deleted: Bool)
}

pub type Contact {
  Contact(
    object: String,
    id: String,
    email: String,
    first_name: Option(String),
    last_name: Option(String),
    created_at: String,
    unsubscribed: Bool,
  )
}

pub type ListContactsResponse {
  ListContactsResponse(object: String, data: List(Contact))
}

/// Builds the JSON payload for creating a contact.
pub fn create_request_body(payload: CreateContact) -> json.Json {
  let CreateContact(
    email:,
    first_name:,
    last_name:,
    unsubscribed:,
    audience_id:,
  ) = payload
  []
  |> types.optional_bool_field("unsubscribed", unsubscribed)
  |> types.optional_string_field("last_name", last_name)
  |> types.optional_string_field("first_name", first_name)
  |> types.prepend(types.string_field("audience_id", audience_id))
  |> types.prepend(types.string_field("email", email))
  |> json.object
}

/// Builds the JSON payload for updating a contact.
pub fn update_request_body(payload: UpdateContact) -> json.Json {
  let UpdateContact(first_name:, last_name:, unsubscribed:) = payload
  []
  |> types.optional_bool_field("unsubscribed", unsubscribed)
  |> types.optional_string_field("last_name", last_name)
  |> types.optional_string_field("first_name", first_name)
  |> json.object
}

/// Creates a contact in the payload's audience and decodes the mutation response.
pub fn create(
  client: glesend.Client,
  payload: CreateContact,
) -> Result(ContactMutationResponse, http.Error) {
  let CreateContact(audience_id:, ..) = payload
  http.post_decoded(
    client,
    http.path_join(["audiences", audience_id, "contacts"]),
    create_request_body(payload),
    contact_mutation_response_decoder(),
  )
}

/// Lists contacts for an audience using the given pagination settings.
pub fn list(
  client: glesend.Client,
  audience_id: String,
  pagination: types.Pagination,
) -> Result(ListContactsResponse, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "contacts"]),
    types.pagination_query(pagination),
    list_contacts_response_decoder(),
  )
}

/// Fetches a contact by audience and contact identifier.
pub fn get(
  client: glesend.Client,
  audience_id: String,
  contact_id: String,
) -> Result(Contact, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["audiences", audience_id, "contacts", contact_id]),
    [],
    contact_decoder(),
  )
}

/// Updates a contact and decodes the mutation response.
pub fn update(
  client: glesend.Client,
  audience_id: String,
  contact_id: String,
  payload: UpdateContact,
) -> Result(ContactMutationResponse, http.Error) {
  http.patch_decoded(
    client,
    http.path_join(["audiences", audience_id, "contacts", contact_id]),
    update_request_body(payload),
    contact_mutation_response_decoder(),
  )
}

/// Deletes a contact and decodes the deletion result.
pub fn delete(
  client: glesend.Client,
  audience_id: String,
  contact_id: String,
) -> Result(DeleteContactResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["audiences", audience_id, "contacts", contact_id]),
    delete_contact_response_decoder(),
  )
}

/// Decodes the API response returned after creating or updating a contact.
pub fn contact_mutation_response_decoder() -> decode.Decoder(
  ContactMutationResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    decode.success(ContactMutationResponse(object: object, id: id))
  }
}

/// Decodes the API response returned after deleting a contact.
pub fn delete_contact_response_decoder() -> decode.Decoder(
  DeleteContactResponse,
) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use deleted <- decode.field("deleted", decode.bool)
    decode.success(DeleteContactResponse(
      object: object,
      id: id,
      deleted: deleted,
    ))
  }
}

/// Decodes a contact resource returned by the API.
pub fn contact_decoder() -> decode.Decoder(Contact) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use email <- decode.field("email", decode.string)
    use first_name <- decode.field("first_name", decode.optional(decode.string))
    use last_name <- decode.field("last_name", decode.optional(decode.string))
    use created_at <- decode.field("created_at", decode.string)
    use unsubscribed <- decode.field("unsubscribed", decode.bool)
    decode.success(Contact(
      object: object,
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      created_at: created_at,
      unsubscribed: unsubscribed,
    ))
  }
}

/// Decodes a contact list response.
pub fn list_contacts_response_decoder() -> decode.Decoder(ListContactsResponse) {
  {
    use object <- decode.field("object", decode.string)
    use data <- decode.field("data", decode.list(of: contact_decoder()))
    decode.success(ListContactsResponse(object: object, data: data))
  }
}
