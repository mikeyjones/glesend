import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type CreateDomain {
  CreateDomain(name: String, region: Option(String))
}

pub type MutationResponse {
  MutationResponse(id: String, object: String)
}

pub type DeleteResponse {
  DeleteResponse(id: String, object: String, deleted: Bool)
}

pub type DomainRecord {
  DomainRecord(
    record: String,
    name: String,
    record_type: String,
    ttl: String,
    status: String,
    value: String,
    priority: Option(Int),
  )
}

pub type Domain {
  Domain(
    id: String,
    name: String,
    status: String,
    created_at: String,
    region: String,
    records: List(DomainRecord),
  )
}

pub type DomainListItem {
  DomainListItem(
    id: String,
    name: String,
    status: String,
    created_at: String,
    region: String,
  )
}

pub type ListDomainsResponse {
  ListDomainsResponse(
    object: String,
    has_more: Bool,
    data: List(DomainListItem),
  )
}

/// Builds the JSON payload for creating a domain.
pub fn create_request_body(payload: CreateDomain) -> json.Json {
  let CreateDomain(name:, region:) = payload
  []
  |> types.optional_string_field("region", region)
  |> types.prepend(types.string_field("name", name))
  |> json.object
}

/// Creates a domain.
pub fn create(
  client: glesend.Client,
  payload: CreateDomain,
) -> Result(Domain, http.Error) {
  http.post_decoded(
    client,
    "/domains",
    create_request_body(payload),
    domain_decoder(),
  )
}

/// Lists domains using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListDomainsResponse, http.Error) {
  http.get_decoded(
    client,
    "/domains",
    types.pagination_query(pagination),
    list_domains_response_decoder(),
  )
}

/// Fetches a domain by its identifier.
pub fn get(
  client: glesend.Client,
  domain_id: String,
) -> Result(Domain, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["domains", domain_id]),
    [],
    domain_decoder(),
  )
}

/// Triggers verification for a domain.
pub fn verify(
  client: glesend.Client,
  domain_id: String,
) -> Result(MutationResponse, http.Error) {
  http.post_decoded(
    client,
    http.path_join(["domains", domain_id, "verify"]),
    json.object([]),
    mutation_response_decoder(),
  )
}

/// Deletes a domain by its identifier.
pub fn delete(
  client: glesend.Client,
  domain_id: String,
) -> Result(DeleteResponse, http.Error) {
  http.delete_decoded(
    client,
    http.path_join(["domains", domain_id]),
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

/// Decodes a domain DNS record.
pub fn domain_record_decoder() -> decode.Decoder(DomainRecord) {
  {
    use record <- decode.field("record", decode.string)
    use name <- decode.field("name", decode.string)
    use record_type <- decode.field("type", decode.string)
    use ttl <- decode.field("ttl", decode.string)
    use status <- decode.field("status", decode.string)
    use value <- decode.field("value", decode.string)
    use priority <- decode.field("priority", decode.optional(decode.int))
    decode.success(DomainRecord(
      record: record,
      name: name,
      record_type: record_type,
      ttl: ttl,
      status: status,
      value: value,
      priority: priority,
    ))
  }
}

/// Decodes a full domain resource.
pub fn domain_decoder() -> decode.Decoder(Domain) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use region <- decode.field("region", decode.string)
    use records <- decode.field(
      "records",
      decode.list(of: domain_record_decoder()),
    )
    decode.success(Domain(
      id: id,
      name: name,
      status: status,
      created_at: created_at,
      region: region,
      records: records,
    ))
  }
}

/// Decodes a domain list item.
pub fn domain_list_item_decoder() -> decode.Decoder(DomainListItem) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use status <- decode.field("status", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use region <- decode.field("region", decode.string)
    decode.success(DomainListItem(
      id: id,
      name: name,
      status: status,
      created_at: created_at,
      region: region,
    ))
  }
}

/// Decodes a paginated domains list response.
pub fn list_domains_response_decoder() -> decode.Decoder(ListDomainsResponse) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field(
      "data",
      decode.list(of: domain_list_item_decoder()),
    )
    decode.success(ListDomainsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
