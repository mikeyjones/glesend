import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type Pagination {
  Pagination(limit: Option(Int), after: Option(String), before: Option(String))
}

/// Creates an empty pagination value with no cursors or limit set.
pub fn pagination() -> Pagination {
  Pagination(limit: None, after: None, before: None)
}

/// Sets the maximum number of items to request in a pagination value.
pub fn with_limit(pagination: Pagination, limit: Int) -> Pagination {
  let Pagination(after:, before:, ..) = pagination
  Pagination(limit: Some(limit), after: after, before: before)
}

/// Sets the forward pagination cursor.
pub fn with_after(pagination: Pagination, after: String) -> Pagination {
  let Pagination(limit:, before:, ..) = pagination
  Pagination(limit: limit, after: Some(after), before: before)
}

/// Sets the backward pagination cursor.
pub fn with_before(pagination: Pagination, before: String) -> Pagination {
  let Pagination(limit:, after:, ..) = pagination
  Pagination(limit: limit, after: after, before: Some(before))
}

/// Converts pagination values into HTTP query parameters.
pub fn pagination_query(pagination: Pagination) -> List(#(String, String)) {
  let Pagination(limit:, after:, before:) = pagination
  []
  |> prepend_option(limit, "limit", int.to_string)
  |> prepend_option(after, "after", identity)
  |> prepend_option(before, "before", identity)
  |> list.reverse
}

/// Builds a JSON object field from a string value.
pub fn string_field(key: String, value: String) -> #(String, json.Json) {
  #(key, json.string(value))
}

/// Builds a JSON object field from a boolean value.
pub fn bool_field(key: String, value: Bool) -> #(String, json.Json) {
  #(key, json.bool(value))
}

/// Prepends a string field when the optional value is present.
pub fn optional_string_field(
  fields: List(#(String, json.Json)),
  key: String,
  value: Option(String),
) -> List(#(String, json.Json)) {
  case value {
    Some(value) -> [#(key, json.string(value)), ..fields]
    None -> fields
  }
}

/// Prepends a boolean field when the optional value is present.
pub fn optional_bool_field(
  fields: List(#(String, json.Json)),
  key: String,
  value: Option(Bool),
) -> List(#(String, json.Json)) {
  case value {
    Some(value) -> [#(key, json.bool(value)), ..fields]
    None -> fields
  }
}

/// Prepends a JSON field to a field list.
pub fn prepend(
  fields: List(#(String, json.Json)),
  field: #(String, json.Json),
) -> List(#(String, json.Json)) {
  [field, ..fields]
}

fn prepend_option(
  items: List(#(String, String)),
  value: Option(a),
  key: String,
  to_string: fn(a) -> String,
) -> List(#(String, String)) {
  case value {
    Some(value) -> [#(key, to_string(value)), ..items]
    None -> items
  }
}

fn identity(value: String) -> String {
  value
}
