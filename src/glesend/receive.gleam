import gleam/dict
import gleam/dynamic/decode
import gleam/option.{type Option, None, unwrap}
import glesend
import glesend/http
import glesend/types

pub type ReceivedEmail {
  ReceivedEmail(
    id: String,
    from: String,
    to: List(String),
    subject: String,
    html: Option(String),
    text: Option(String),
    created_at: String,
    reply_to: List(String),
    cc: List(String),
    bcc: List(String),
    message_id: Option(String),
    headers: dict.Dict(String, String),
    attachments: List(ReceivedEmailAttachment),
  )
}

/// Attachment metadata as returned on [`get`](#get) (single received email).
/// Unlike [`Attachment`](#Attachment), `size` may be absent and Resend includes
/// `content_disposition` / `content_id` for MIME parts.
pub type ReceivedEmailAttachment {
  ReceivedEmailAttachment(
    id: String,
    filename: String,
    content_type: String,
    size: Option(Int),
    content_disposition: Option(String),
    content_id: Option(String),
  )
}

pub type ListReceivedEmailsResponse {
  ListReceivedEmailsResponse(
    object: String,
    has_more: Bool,
    data: List(ReceivedEmail),
  )
}

pub type Attachment {
  Attachment(id: String, filename: String, content_type: String, size: Int)
}

pub type ListAttachmentsResponse {
  ListAttachmentsResponse(data: List(Attachment), has_more: Bool)
}

pub type RetrievedAttachment {
  RetrievedAttachment(
    id: String,
    filename: String,
    content_type: String,
    size: Int,
    content: String,
  )
}

/// Lists received emails using the given pagination settings.
pub fn list(
  client: glesend.Client,
  pagination: types.Pagination,
) -> Result(ListReceivedEmailsResponse, http.Error) {
  http.get_decoded(
    client,
    "/emails/receiving",
    types.pagination_query(pagination),
    list_received_emails_response_decoder(),
  )
}

/// Fetches a single received email by its identifier.
pub fn get(
  client: glesend.Client,
  email_id: String,
) -> Result(ReceivedEmail, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["emails", "receiving", email_id]),
    [],
    received_email_decoder(),
  )
}

/// Lists attachments for a received email using the given pagination settings.
pub fn list_attachments(
  client: glesend.Client,
  email_id: String,
  pagination: types.Pagination,
) -> Result(ListAttachmentsResponse, http.Error) {
  http.get_decoded(
    client,
    http.path_join(["emails", "receiving", email_id, "attachments"]),
    types.pagination_query(pagination),
    list_attachments_response_decoder(),
  )
}

/// Fetches a single attachment for a received email.
pub fn get_attachment(
  client: glesend.Client,
  email_id: String,
  attachment_id: String,
) -> Result(RetrievedAttachment, http.Error) {
  http.get_decoded(
    client,
    http.path_join([
      "emails",
      "receiving",
      email_id,
      "attachments",
      attachment_id,
    ]),
    [],
    retrieved_attachment_decoder(),
  )
}

/// Decodes `to` / `cc` / etc. as Resend returns: string arrays, with legacy
/// single-string and JSON `null` tolerated.
fn address_list_decoder() -> decode.Decoder(List(String)) {
  decode.one_of(decode.list(of: decode.string), or: [
    decode.then(decode.string, fn(s) { decode.success([s]) }),
    decode.map(decode.optional(decode.list(of: decode.string)), fn(opt) {
      option.unwrap(opt, [])
    }),
  ])
}

/// Decodes a received email attachment summary.
pub fn attachment_decoder() -> decode.Decoder(Attachment) {
  {
    use id <- decode.field("id", decode.string)
    use filename <- decode.field("filename", decode.string)
    use content_type <- decode.field("content_type", decode.string)
    use size <- decode.field("size", decode.int)
    decode.success(Attachment(
      id: id,
      filename: filename,
      content_type: content_type,
      size: size,
    ))
  }
}

/// Decodes an attachment object embedded in a single received email response.
pub fn received_email_attachment_decoder() -> decode.Decoder(
  ReceivedEmailAttachment,
) {
  {
    use id <- decode.field("id", decode.string)
    use filename <- decode.field("filename", decode.string)
    use content_type <- decode.field("content_type", decode.string)
    use size <- decode.optional_field("size", None, decode.optional(decode.int))
    use content_disposition <- decode.optional_field(
      "content_disposition",
      None,
      decode.optional(decode.string),
    )
    use content_id <- decode.optional_field(
      "content_id",
      None,
      decode.optional(decode.string),
    )
    decode.success(ReceivedEmailAttachment(
      id: id,
      filename: filename,
      content_type: content_type,
      size: size,
      content_disposition: content_disposition,
      content_id: content_id,
    ))
  }
}

/// Decodes a received email resource.
pub fn received_email_decoder() -> decode.Decoder(ReceivedEmail) {
  {
    use id <- decode.field("id", decode.string)
    use from <- decode.field("from", decode.string)
    use to <- decode.field("to", address_list_decoder())
    use subject <- decode.field("subject", decode.string)
    use html <- decode.optional_field(
      "html",
      None,
      decode.optional(decode.string),
    )
    use text <- decode.optional_field(
      "text",
      None,
      decode.optional(decode.string),
    )
    use created_at <- decode.field("created_at", decode.string)
    use reply_to <- decode.optional_field(
      "reply_to",
      [],
      address_list_decoder(),
    )
    use cc <- decode.optional_field("cc", [], address_list_decoder())
    use bcc <- decode.optional_field("bcc", [], address_list_decoder())
    use message_id <- decode.optional_field(
      "message_id",
      None,
      decode.optional(decode.string),
    )
    use headers <- decode.optional_field(
      "headers",
      dict.new(),
      decode.map(
        decode.optional(decode.dict(decode.string, decode.string)),
        fn(opt) { unwrap(opt, dict.new()) },
      ),
    )
    use attachments <- decode.optional_field(
      "attachments",
      [],
      decode.list(of: received_email_attachment_decoder()),
    )
    decode.success(ReceivedEmail(
      id: id,
      from: from,
      to: to,
      subject: subject,
      html: html,
      text: text,
      created_at: created_at,
      reply_to: reply_to,
      cc: cc,
      bcc: bcc,
      message_id: message_id,
      headers: headers,
      attachments: attachments,
    ))
  }
}

/// Decodes a received emails list response.
pub fn list_received_emails_response_decoder() -> decode.Decoder(
  ListReceivedEmailsResponse,
) {
  {
    use object <- decode.optional_field("object", "list", decode.string)
    use has_more <- decode.optional_field("has_more", False, decode.bool)
    use data <- decode.field("data", decode.list(of: received_email_decoder()))
    decode.success(ListReceivedEmailsResponse(
      object: object,
      has_more: has_more,
      data: data,
    ))
  }
}

/// Decodes a received email attachments list response.
pub fn list_attachments_response_decoder() -> decode.Decoder(
  ListAttachmentsResponse,
) {
  {
    use data <- decode.field("data", decode.list(of: attachment_decoder()))
    use has_more <- decode.optional_field("has_more", False, decode.bool)
    decode.success(ListAttachmentsResponse(data: data, has_more: has_more))
  }
}

/// Decodes a retrieved attachment including its content.
pub fn retrieved_attachment_decoder() -> decode.Decoder(RetrievedAttachment) {
  {
    use id <- decode.field("id", decode.string)
    use filename <- decode.field("filename", decode.string)
    use content_type <- decode.field("content_type", decode.string)
    use size <- decode.field("size", decode.int)
    use content <- decode.field("content", decode.string)
    decode.success(RetrievedAttachment(
      id: id,
      filename: filename,
      content_type: content_type,
      size: size,
      content: content,
    ))
  }
}
