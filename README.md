# glesend

[![Package Version](https://img.shields.io/hexpm/v/glesend)](https://hex.pm/packages/glesend)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glesend/)

```sh
gleam add glesend@1
```

## Send an email

```gleam
import gleam/io
import gleam/option.{None, Some}
import glesend
import glesend/emails

pub fn main() -> Nil {
  let client = glesend.new(api_key: "re_123")
  let payload =
    emails.SendEmail(
      from: "Acme <onboarding@resend.dev>",
      to: ["delivered@resend.dev"],
      subject: "Welcome to glesend",
      html: Some("<strong>Hello from Gleam!</strong>"),
      text: Some("Hello from Gleam!"),
      reply_to: None,
    )

  case emails.send(client, payload) {
    Ok(emails.SendResponse(id: id)) ->
      io.println("Sent email with id: " <> id)

    Error(error) ->
      io.debug(error)
  }
}
```

Further documentation can be found at <https://hexdocs.pm/glesend>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
