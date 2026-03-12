import gleam/dynamic/decode
import gleam/option.{type Option}
import glesend
import glesend/http
import glesend/types

pub type ReceivedEmail {
  ReceivedEmail(
    id: String,
    from: String,
    to: String,
    subject: String,
    html: Option(String),
    text: Option(String),
    created_at: String,
    reply_to: Option(String),
    cc: Option(String),
    bcc: Option(String),
  )
}

pub type ListReceivedEmailsResponse {
  ListReceivedEmailsResponse(data: List(ReceivedEmail))
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

/// Decodes a received email resource.
pub fn received_email_decoder() -> decode.Decoder(ReceivedEmail) {
  {
    use id <- decode.field("id", decode.string)
    use from <- decode.field("from", decode.string)
    use to <- decode.field("to", decode.string)
    use subject <- decode.field("subject", decode.string)
    use html <- decode.field("html", decode.optional(decode.string))
    use text <- decode.field("text", decode.optional(decode.string))
    use created_at <- decode.field("created_at", decode.string)
    use reply_to <- decode.field("reply_to", decode.optional(decode.string))
    use cc <- decode.field("cc", decode.optional(decode.string))
    use bcc <- decode.field("bcc", decode.optional(decode.string))
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
    ))
  }
}

/// Decodes a received emails list response.
pub fn list_received_emails_response_decoder() -> decode.Decoder(
  ListReceivedEmailsResponse,
) {
  {
    use data <- decode.field("data", decode.list(of: received_email_decoder()))
    decode.success(ListReceivedEmailsResponse(data: data))
  }
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
