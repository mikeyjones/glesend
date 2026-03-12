import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type SendEmail {
  SendEmail(
    from: String,
    to: List(String),
    subject: String,
    html: Option(String),
    text: Option(String),
    reply_to: Option(String),
  )
}

pub type SendBatchEmail {
  SendBatchEmail(
    from: String,
    to: List(String),
    subject: String,
    html: Option(String),
    text: Option(String),
    reply_to: Option(String),
  )
}

pub type SendResponse {
  SendResponse(id: String)
}

pub type BatchSendItem {
  BatchSendItem(id: String)
}

pub type BatchSendResponse {
  BatchSendResponse(data: List(BatchSendItem))
}

pub type Email {
  Email(
    object: String,
    id: String,
    to: List(String),
    from: String,
    created_at: String,
    subject: String,
    html: Option(String),
    text: Option(String),
    last_event: String,
    status: String,
  )
}

pub type ListEmailsResponse {
  ListEmailsResponse(object: String, has_more: Bool, data: List(Email))
}

/// Builds the JSON payload for sending a single email.
pub fn send_request_body(payload: SendEmail) -> json.Json {
  let SendEmail(from:, to:, subject:, html:, text:, reply_to:) = payload
  []
  |> types.optional_string_field("reply_to", reply_to)
  |> types.optional_string_field("text", text)
  |> types.optional_string_field("html", html)
  |> types.prepend(types.string_field("subject", subject))
  |> types.prepend(#("to", json.array(to, of: json.string)))
  |> types.prepend(types.string_field("from", from))
  |> json.object
}

/// Builds the JSON payload for sending a batch of emails.
pub fn send_batch_request_body(payloads: List(SendBatchEmail)) -> json.Json {
  payloads
  |> list.map(fn(payload) {
    let SendBatchEmail(from:, to:, subject:, html:, text:, reply_to:) = payload
    []
    |> types.optional_string_field("reply_to", reply_to)
    |> types.optional_string_field("text", text)
    |> types.optional_string_field("html", html)
    |> types.prepend(types.string_field("subject", subject))
    |> types.prepend(#("to", json.array(to, of: json.string)))
    |> types.prepend(types.string_field("from", from))
    |> json.object
  })
  |> json.preprocessed_array
}

/// Sends a single email and decodes the created email identifier.
pub fn send(
  client: glesend.Client,
  payload: SendEmail,
) -> Result(SendResponse, http.Error) {
  http.post_decoded(
    client,
    "/emails",
    send_request_body(payload),
    send_response_decoder(),
  )
}

/// Lists sent emails using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListEmailsResponse, http.Error) {
  http.get_decoded(
    client,
    "/emails",
    types.pagination_query(pagination),
    list_emails_response_decoder(),
  )
}

/// Fetches a single email by its identifier.
pub fn get(
  client: glesend.Client,
  email_id: String,
) -> Result(Email, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["emails", email_id]),
    [],
    email_decoder(),
  )
}

/// Cancels a scheduled email and returns its identifier.
pub fn cancel(
  client: glesend.Client,
  email_id: String,
) -> Result(SendResponse, http.Error) {
  http.post_decoded(
    client,
    http.path_join(["emails", email_id, "cancel"]),
    json.object([]),
    send_response_decoder(),
  )
}

/// Sends multiple emails in one request and decodes their identifiers.
pub fn send_batch(
  client: glesend.Client,
  payloads: List(SendBatchEmail),
) -> Result(BatchSendResponse, http.Error) {
  http.post_decoded(
    client,
    "/emails/batch",
    send_batch_request_body(payloads),
    batch_send_response_decoder(),
  )
}

/// Decodes a single-email send response.
pub fn send_response_decoder() -> decode.Decoder(SendResponse) {
  {
    use id <- decode.field("id", decode.string)
    decode.success(SendResponse(id: id))
  }
}

/// Decodes an item from a batch send response.
pub fn batch_send_item_decoder() -> decode.Decoder(BatchSendItem) {
  {
    use id <- decode.field("id", decode.string)
    decode.success(BatchSendItem(id: id))
  }
}

/// Decodes a batch send response payload.
pub fn batch_send_response_decoder() -> decode.Decoder(BatchSendResponse) {
  {
    use data <- decode.field("data", decode.list(of: batch_send_item_decoder()))
    decode.success(BatchSendResponse(data: data))
  }
}

/// Decodes an email resource returned by the API.
pub fn email_decoder() -> decode.Decoder(Email) {
  {
    use object <- decode.field("object", decode.string)
    use id <- decode.field("id", decode.string)
    use to <- decode.field("to", decode.list(of: decode.string))
    use from <- decode.field("from", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    use subject <- decode.field("subject", decode.string)
    use html <- decode.field("html", decode.optional(decode.string))
    use text <- decode.field("text", decode.optional(decode.string))
    use last_event <- decode.field("last_event", decode.string)
    use status <- decode.field("status", decode.string)
    decode.success(Email(
      object: object,
      id: id,
      to: to,
      from: from,
      created_at: created_at,
      subject: subject,
      html: html,
      text: text,
      last_event: last_event,
      status: status,
    ))
  }
}

/// Decodes a paginated email list response.
pub fn list_emails_response_decoder() -> decode.Decoder(ListEmailsResponse) {
  {
    use object <- decode.field("object", decode.string)
    use has_more <- decode.field("has_more", decode.bool)
    use data <- decode.field("data", decode.list(of: email_decoder()))
    decode.success(ListEmailsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}
