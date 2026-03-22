import gleam/json
import gleam/option.{None, Some}
import gleeunit
import glesend/audiences
import glesend/broadcasts
import glesend/contacts
import glesend/domains
import glesend/emails
import glesend/http
import glesend/receive
import glesend/templates
import glesend/topics
import glesend/types
import glesend/webhooks

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn pagination_query_test() {
  let query =
    types.pagination()
    |> types.with_limit(25)
    |> types.with_after("cursor")
    |> types.pagination_query

  assert query == [#("limit", "25"), #("after", "cursor")]
}

pub fn pagination_query_empty_test() {
  let query = types.pagination() |> types.pagination_query
  assert query == []
}

pub fn path_join_test() {
  assert http.path_join(["audiences", "aud_123", "contacts"])
    == "/audiences/aud_123/contacts"
}

pub fn prepend_test() {
  let fields =
    []
    |> types.prepend(types.string_field("a", "1"))
    |> types.prepend(types.string_field("b", "2"))
  assert fields == [#("b", json.string("2")), #("a", json.string("1"))]
}

pub fn optional_string_field_none_test() {
  let fields =
    []
    |> types.optional_string_field("key", None)
  assert fields == []
}

pub fn optional_string_field_some_test() {
  let fields =
    []
    |> types.optional_string_field("key", Some("val"))
  assert fields == [#("key", json.string("val"))]
}

pub fn email_send_request_body_test() {
  let body =
    emails.SendEmail(
      from: "from@example.com",
      to: ["to@example.com"],
      subject: "Hello",
      html: Some("<p>Hi</p>"),
      text: None,
      reply_to: Some("reply@example.com"),
    )
    |> emails.send_request_body
    |> json.to_string

  assert body
    == "{\"from\":\"from@example.com\",\"to\":[\"to@example.com\"],\"subject\":\"Hello\",\"html\":\"<p>Hi</p>\",\"reply_to\":\"reply@example.com\"}"
}

pub fn email_send_request_body_minimal_test() {
  let body =
    emails.SendEmail(
      from: "a@b.com",
      to: ["c@d.com"],
      subject: "S",
      html: None,
      text: None,
      reply_to: None,
    )
    |> emails.send_request_body
    |> json.to_string

  assert body == "{\"from\":\"a@b.com\",\"to\":[\"c@d.com\"],\"subject\":\"S\"}"
}

pub fn batch_email_request_body_test() {
  let body =
    [
      emails.SendBatchEmail(
        from: "a@b.com",
        to: ["c@d.com"],
        subject: "Hi",
        html: None,
        text: None,
        reply_to: Some("r@b.com"),
      ),
    ]
    |> emails.send_batch_request_body
    |> json.to_string

  assert body
    == "[{\"from\":\"a@b.com\",\"to\":[\"c@d.com\"],\"subject\":\"Hi\",\"reply_to\":\"r@b.com\"}]"
}

pub fn broadcast_update_request_body_test() {
  let body =
    broadcasts.UpdateBroadcast(
      name: Some("Launch"),
      subject: None,
      reply_to: Some("team@example.com"),
    )
    |> broadcasts.update_request_body
    |> json.to_string

  assert body == "{\"name\":\"Launch\",\"reply_to\":\"team@example.com\"}"
}

pub fn broadcast_update_request_body_empty_test() {
  let body =
    broadcasts.UpdateBroadcast(name: None, subject: None, reply_to: None)
    |> broadcasts.update_request_body
    |> json.to_string

  assert body == "{}"
}

pub fn template_update_request_body_test() {
  let body =
    templates.UpdateTemplate(
      name: Some("New"),
      subject: None,
      html: Some("<p>Hi</p>"),
    )
    |> templates.update_request_body
    |> json.to_string

  assert body == "{\"name\":\"New\",\"html\":\"<p>Hi</p>\"}"
}

pub fn email_decoder_test() {
  let json_string =
    "{\"object\":\"email\",\"id\":\"eml_123\",\"to\":[\"to@example.com\"],\"from\":\"from@example.com\",\"created_at\":\"2026-03-12T10:00:00Z\",\"subject\":\"Hello\",\"html\":\"<p>Hi</p>\",\"text\":\"Hi\",\"last_event\":\"delivered\",\"status\":\"sent\"}"

  let result = json.parse(json_string, using: emails.email_decoder())

  assert result
    == Ok(emails.Email(
      object: "email",
      id: "eml_123",
      to: ["to@example.com"],
      from: "from@example.com",
      created_at: "2026-03-12T10:00:00Z",
      subject: "Hello",
      html: Some("<p>Hi</p>"),
      text: Some("Hi"),
      last_event: "delivered",
      status: "sent",
    ))
}

pub fn contact_list_decoder_test() {
  let json_string =
    "{\"object\":\"list\",\"data\":[{\"object\":\"contact\",\"id\":\"con_123\",\"email\":\"jane@example.com\",\"first_name\":\"Jane\",\"last_name\":\"Doe\",\"created_at\":\"2026-03-12T10:00:00Z\",\"unsubscribed\":false}]}"

  let result =
    json.parse(json_string, using: contacts.list_contacts_response_decoder())

  assert result
    == Ok(
      contacts.ListContactsResponse(object: "list", data: [
        contacts.Contact(
          object: "contact",
          id: "con_123",
          email: "jane@example.com",
          first_name: Some("Jane"),
          last_name: Some("Doe"),
          created_at: "2026-03-12T10:00:00Z",
          unsubscribed: False,
        ),
      ]),
    )
}

pub fn broadcast_mutation_response_decoder_test() {
  let json_string = "{\"id\":\"bc_123\",\"object\":\"broadcast\"}"
  let result =
    json.parse(json_string, using: broadcasts.mutation_response_decoder())
  assert result
    == Ok(broadcasts.MutationResponse(id: "bc_123", object: "broadcast"))
}

pub fn broadcast_delete_response_decoder_test() {
  let json_string =
    "{\"id\":\"bc_123\",\"object\":\"broadcast\",\"deleted\":true}"
  let result =
    json.parse(json_string, using: broadcasts.delete_response_decoder())
  assert result
    == Ok(broadcasts.DeleteResponse(
      id: "bc_123",
      object: "broadcast",
      deleted: True,
    ))
}

pub fn audience_decoder_test() {
  let json_string =
    "{\"id\":\"aud_1\",\"object\":\"audience\",\"name\":\"News\",\"created_at\":\"2026-01-01\"}"
  let result = json.parse(json_string, using: audiences.audience_decoder())
  assert result
    == Ok(audiences.Audience(
      id: "aud_1",
      object: "audience",
      name: "News",
      created_at: "2026-01-01",
    ))
}

pub fn topic_decoder_test() {
  let json_string =
    "{\"id\":\"top_1\",\"object\":\"topic\",\"name\":\"Updates\",\"created_at\":\"2026-01-01\"}"
  let result = json.parse(json_string, using: topics.topic_decoder())
  assert result
    == Ok(topics.Topic(
      id: "top_1",
      object: "topic",
      name: "Updates",
      created_at: "2026-01-01",
    ))
}

pub fn domain_record_decoder_test() {
  let json_string =
    "{\"record\":\"SPF\",\"name\":\"example.com\",\"type\":\"TXT\",\"ttl\":\"Auto\",\"status\":\"verified\",\"value\":\"v=spf1\",\"priority\":null}"
  let result = json.parse(json_string, using: domains.domain_record_decoder())
  assert result
    == Ok(domains.DomainRecord(
      record: "SPF",
      name: "example.com",
      record_type: "TXT",
      ttl: "Auto",
      status: "verified",
      value: "v=spf1",
      priority: None,
    ))
}

pub fn webhook_list_item_decoder_test() {
  let json_string =
    "{\"id\":\"wh_1\",\"endpoint\":\"https://example.com/hook\",\"events\":[\"email.sent\"],\"status\":\"active\",\"created_at\":\"2026-01-01\"}"
  let result =
    json.parse(json_string, using: webhooks.webhook_list_item_decoder())
  assert result
    == Ok(webhooks.WebhookListItem(
      id: "wh_1",
      endpoint: "https://example.com/hook",
      events: ["email.sent"],
      status: "active",
      created_at: "2026-01-01",
    ))
}

pub fn webhook_update_request_body_test() {
  let body =
    webhooks.UpdateWebhook(
      url: Some("https://new.com"),
      enabled: None,
      events: None,
      description: None,
    )
    |> webhooks.update_request_body
    |> json.to_string

  assert body == "{\"url\":\"https://new.com\"}"
}

pub fn contact_create_request_body_all_none_test() {
  let body =
    contacts.CreateContact(
      email: "a@b.com",
      first_name: None,
      last_name: None,
      unsubscribed: None,
      audience_id: "aud_1",
    )
    |> contacts.create_request_body
    |> json.to_string

  assert body == "{\"email\":\"a@b.com\",\"audience_id\":\"aud_1\"}"
}

pub fn received_email_decoder_test() {
  let json_string =
    "{\"id\":\"recv_1\",\"from\":\"sender@example.com\",\"to\":[\"inbox@example.com\"],\"subject\":\"Hello\",\"html\":\"<p>Hi</p>\",\"text\":\"Hi\",\"created_at\":\"2026-03-12T10:00:00Z\",\"reply_to\":[\"reply@example.com\"],\"cc\":[\"cc@example.com\"],\"bcc\":[\"bcc@example.com\"],\"message_id\":\"<id@host>\",\"attachments\":[]}"

  let result = json.parse(json_string, using: receive.received_email_decoder())

  assert result
    == Ok(
      receive.ReceivedEmail(
        id: "recv_1",
        from: "sender@example.com",
        to: ["inbox@example.com"],
        subject: "Hello",
        html: Some("<p>Hi</p>"),
        text: Some("Hi"),
        created_at: "2026-03-12T10:00:00Z",
        reply_to: ["reply@example.com"],
        cc: ["cc@example.com"],
        bcc: ["bcc@example.com"],
        message_id: Some("<id@host>"),
        attachments: [],
      ),
    )
}

pub fn received_email_decoder_legacy_string_addresses_test() {
  let json_string =
    "{\"id\":\"recv_1\",\"from\":\"sender@example.com\",\"to\":\"inbox@example.com\",\"subject\":\"Hello\",\"html\":\"<p>Hi</p>\",\"text\":\"Hi\",\"created_at\":\"2026-03-12T10:00:00Z\",\"reply_to\":\"reply@example.com\",\"cc\":\"cc@example.com\",\"bcc\":\"bcc@example.com\"}"

  let result = json.parse(json_string, using: receive.received_email_decoder())

  assert result
    == Ok(
      receive.ReceivedEmail(
        id: "recv_1",
        from: "sender@example.com",
        to: ["inbox@example.com"],
        subject: "Hello",
        html: Some("<p>Hi</p>"),
        text: Some("Hi"),
        created_at: "2026-03-12T10:00:00Z",
        reply_to: ["reply@example.com"],
        cc: ["cc@example.com"],
        bcc: ["bcc@example.com"],
        message_id: None,
        attachments: [],
      ),
    )
}

pub fn received_email_decoder_optional_fields_test() {
  let json_string =
    "{\"id\":\"recv_1\",\"from\":\"sender@example.com\",\"to\":[\"inbox@example.com\"],\"subject\":\"Hello\",\"html\":null,\"text\":null,\"created_at\":\"2026-03-12T10:00:00Z\",\"reply_to\":null,\"cc\":null,\"bcc\":null}"

  let result = json.parse(json_string, using: receive.received_email_decoder())

  assert result
    == Ok(
      receive.ReceivedEmail(
        id: "recv_1",
        from: "sender@example.com",
        to: ["inbox@example.com"],
        subject: "Hello",
        html: None,
        text: None,
        created_at: "2026-03-12T10:00:00Z",
        reply_to: [],
        cc: [],
        bcc: [],
        message_id: None,
        attachments: [],
      ),
    )
}

pub fn list_received_emails_response_resend_shape_test() {
  // Mirrors Resend receiving list: array addressing, no html/text keys.
  let json_string =
    "{\"data\":[{\"cc\":[],\"id\":\"4c20261a-25fd-4f34-8e69-d74247539046\",\"to\":[\"test2-ycwzob@email.testyusers.com\"],\"bcc\":[],\"from\":\"mikeyj2009@googlemail.com\",\"subject\":\"test\",\"reply_to\":[],\"created_at\":\"2026-03-22 17:18:52.128297+00\",\"message_id\":\"<CAMaFO1450g_CiTO_qnEmHw78RG4=aa=5uz4nD+YUpWiRJX5eUg@mail.gmail.com>\",\"attachments\":[]}],\"object\":\"list\",\"has_more\":false}"

  let result =
    json.parse(
      json_string,
      using: receive.list_received_emails_response_decoder(),
    )

  assert result
    == Ok(
      receive.ListReceivedEmailsResponse(object: "list", has_more: False, data: [
        receive.ReceivedEmail(
          id: "4c20261a-25fd-4f34-8e69-d74247539046",
          from: "mikeyj2009@googlemail.com",
          to: ["test2-ycwzob@email.testyusers.com"],
          subject: "test",
          html: None,
          text: None,
          created_at: "2026-03-22 17:18:52.128297+00",
          reply_to: [],
          cc: [],
          bcc: [],
          message_id: Some(
            "<CAMaFO1450g_CiTO_qnEmHw78RG4=aa=5uz4nD+YUpWiRJX5eUg@mail.gmail.com>",
          ),
          attachments: [],
        ),
      ]),
    )
}

pub fn list_received_emails_response_decoder_test() {
  let json_string =
    "{\"object\":\"list\",\"has_more\":false,\"data\":[{\"id\":\"recv_1\",\"from\":\"sender@example.com\",\"to\":[\"inbox@example.com\"],\"subject\":\"Hello\",\"html\":null,\"text\":\"Hi\",\"created_at\":\"2026-03-12T10:00:00Z\",\"reply_to\":[],\"cc\":[],\"bcc\":[],\"message_id\":null,\"attachments\":[]}]}"

  let result =
    json.parse(
      json_string,
      using: receive.list_received_emails_response_decoder(),
    )

  assert result
    == Ok(
      receive.ListReceivedEmailsResponse(object: "list", has_more: False, data: [
        receive.ReceivedEmail(
          id: "recv_1",
          from: "sender@example.com",
          to: ["inbox@example.com"],
          subject: "Hello",
          html: None,
          text: Some("Hi"),
          created_at: "2026-03-12T10:00:00Z",
          reply_to: [],
          cc: [],
          bcc: [],
          message_id: None,
          attachments: [],
        ),
      ]),
    )
}

pub fn received_email_decoder_single_get_test() {
  // GET /emails/receiving/:id — extra keys (object, headers, raw) ignored.
  let json_string =
    "{\"object\":\"email\",\"id\":\"4ef9a417-02e9-4d39-ad75-9611e0fcc33c\",\"to\":[\"delivered@resend.dev\"],\"from\":\"Acme <onboarding@resend.dev>\",\"created_at\":\"2023-04-03T22:13:42.674981+00:00\",\"subject\":\"Hello World\",\"html\":\"Congrats on sending your <strong>first email</strong>!\",\"text\":null,\"headers\":{\"return-path\":\"lucas.costa@resend.com\",\"mime-version\":\"1.0\"},\"bcc\":[],\"cc\":[],\"reply_to\":[],\"message_id\":\"<example+123>\",\"raw\":{\"download_url\":\"https://example.resend.com/receiving/raw/054da427-439a-4e91-b785-e4fb1966285f?Signature=...\",\"expires_at\":\"2023-04-03T23:13:42.674981+00:00\"},\"attachments\":[{\"id\":\"2a0c9ce0-3112-4728-976e-47ddcd16a318\",\"filename\":\"avatar.png\",\"content_type\":\"image/png\",\"content_disposition\":\"inline\",\"content_id\":\"img001\"},{\"id\":\"3b1d0df1-4223-5839-087f-54eedd27b419\",\"filename\":\"document.pdf\",\"content_type\":\"application/pdf\",\"content_disposition\":null,\"content_id\":null}]}"

  let result = json.parse(json_string, using: receive.received_email_decoder())

  assert result
    == Ok(
      receive.ReceivedEmail(
        id: "4ef9a417-02e9-4d39-ad75-9611e0fcc33c",
        from: "Acme <onboarding@resend.dev>",
        to: ["delivered@resend.dev"],
        subject: "Hello World",
        html: Some("Congrats on sending your <strong>first email</strong>!"),
        text: None,
        created_at: "2023-04-03T22:13:42.674981+00:00",
        reply_to: [],
        cc: [],
        bcc: [],
        message_id: Some("<example+123>"),
        attachments: [
          receive.ReceivedEmailAttachment(
            id: "2a0c9ce0-3112-4728-976e-47ddcd16a318",
            filename: "avatar.png",
            content_type: "image/png",
            size: None,
            content_disposition: Some("inline"),
            content_id: Some("img001"),
          ),
          receive.ReceivedEmailAttachment(
            id: "3b1d0df1-4223-5839-087f-54eedd27b419",
            filename: "document.pdf",
            content_type: "application/pdf",
            size: None,
            content_disposition: None,
            content_id: None,
          ),
        ],
      ),
    )
}

pub fn received_email_attachment_decoder_with_size_test() {
  let json_string =
    "{\"id\":\"att_1\",\"filename\":\"f.bin\",\"content_type\":\"application/octet-stream\",\"size\":99}"

  let result =
    json.parse(json_string, using: receive.received_email_attachment_decoder())

  assert result
    == Ok(receive.ReceivedEmailAttachment(
      id: "att_1",
      filename: "f.bin",
      content_type: "application/octet-stream",
      size: Some(99),
      content_disposition: None,
      content_id: None,
    ))
}

pub fn attachment_decoder_test() {
  let json_string =
    "{\"id\":\"att_1\",\"filename\":\"invoice.pdf\",\"content_type\":\"application/pdf\",\"size\":12345}"

  let result = json.parse(json_string, using: receive.attachment_decoder())

  assert result
    == Ok(receive.Attachment(
      id: "att_1",
      filename: "invoice.pdf",
      content_type: "application/pdf",
      size: 12_345,
    ))
}

pub fn list_attachments_response_decoder_test() {
  let json_string =
    "{\"data\":[{\"id\":\"att_1\",\"filename\":\"invoice.pdf\",\"content_type\":\"application/pdf\",\"size\":12345}],\"has_more\":false}"

  let result =
    json.parse(json_string, using: receive.list_attachments_response_decoder())

  assert result
    == Ok(receive.ListAttachmentsResponse(
      data: [
        receive.Attachment(
          id: "att_1",
          filename: "invoice.pdf",
          content_type: "application/pdf",
          size: 12_345,
        ),
      ],
      has_more: False,
    ))
}

pub fn retrieved_attachment_decoder_test() {
  let json_string =
    "{\"id\":\"att_1\",\"filename\":\"invoice.pdf\",\"content_type\":\"application/pdf\",\"size\":12345,\"content\":\"SGVsbG8=\"}"

  let result =
    json.parse(json_string, using: receive.retrieved_attachment_decoder())

  assert result
    == Ok(receive.RetrievedAttachment(
      id: "att_1",
      filename: "invoice.pdf",
      content_type: "application/pdf",
      size: 12_345,
      content: "SGVsbG8=",
    ))
}
