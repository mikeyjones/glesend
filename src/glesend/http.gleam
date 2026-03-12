import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glesend

pub type Error {
  InvalidUrl
  HttpError(httpc.HttpError)
  ApiError(status: Int, body: String)
  DecodeError(body: String, errors: List(decode.DecodeError))
  JsonParseError(body: String, error: json.DecodeError)
}

pub type Response {
  Response(status: Int, body: String, data: Option(Dynamic))
}

/// Decodes a successful HTTP response body with the given decoder.
pub fn decode_response(
  response: Response,
  decoder: decode.Decoder(t),
) -> Result(t, Error) {
  let Response(body:, data:, ..) = response
  case data {
    Some(data) ->
      decode.run(data, decoder)
      |> result.map_error(fn(errors) { DecodeError(body: body, errors: errors) })

    None ->
      case body == "" {
        True ->
          Error(
            DecodeError(body: body, errors: [
              decode.DecodeError(expected: "JSON", found: "Nil", path: []),
            ]),
          )

        False ->
          case json.parse(body, using: decode.dynamic) {
            Ok(data) ->
              decode.run(data, decoder)
              |> result.map_error(fn(errors) {
                DecodeError(body: body, errors: errors)
              })
            Error(json_error) ->
              Error(JsonParseError(body: body, error: json_error))
          }
      }
  }
}

/// Sends a GET request and decodes the JSON response body.
pub fn get_decoded(
  client: glesend.Client,
  path: String,
  query: List(#(String, String)),
  decoder: decode.Decoder(t),
) -> Result(t, Error) {
  use response <- result.try(get(client, path, query))
  decode_response(response, decoder)
}

/// Sends a POST request and decodes the JSON response body.
pub fn post_decoded(
  client: glesend.Client,
  path: String,
  body: json.Json,
  decoder: decode.Decoder(t),
) -> Result(t, Error) {
  use response <- result.try(post(client, path, body))
  decode_response(response, decoder)
}

/// Sends a PATCH request and decodes the JSON response body.
pub fn patch_decoded(
  client: glesend.Client,
  path: String,
  body: json.Json,
  decoder: decode.Decoder(t),
) -> Result(t, Error) {
  use response <- result.try(patch(client, path, body))
  decode_response(response, decoder)
}

/// Sends a DELETE request and decodes the JSON response body.
pub fn delete_decoded(
  client: glesend.Client,
  path: String,
  decoder: decode.Decoder(t),
) -> Result(t, Error) {
  use response <- result.try(delete(client, path))
  decode_response(response, decoder)
}

/// Sends a raw GET request and returns the response without decoding it.
pub fn get(
  client: glesend.Client,
  path: String,
  query: List(#(String, String)),
) -> Result(Response, Error) {
  send(client, http.Get, path, query, None)
}

/// Sends a raw POST request with a JSON body.
pub fn post(
  client: glesend.Client,
  path: String,
  body: json.Json,
) -> Result(Response, Error) {
  send(client, http.Post, path, [], Some(body))
}

/// Sends a raw PATCH request with a JSON body.
pub fn patch(
  client: glesend.Client,
  path: String,
  body: json.Json,
) -> Result(Response, Error) {
  send(client, http.Patch, path, [], Some(body))
}

/// Sends a raw DELETE request.
pub fn delete(client: glesend.Client, path: String) -> Result(Response, Error) {
  send(client, http.Delete, path, [], None)
}

/// Joins path segments into an absolute API path.
pub fn path_join(parts: List(String)) -> String {
  "/" <> string.join(parts, with: "/")
}

/// Sends an HTTP request with the client configuration and validates the result.
pub fn send(
  client: glesend.Client,
  method: http.Method,
  path: String,
  query: List(#(String, String)),
  body: Option(json.Json),
) -> Result(Response, Error) {
  let glesend.Client(api_key:, base_url:) = client
  use req <- result.try(
    request.to(base_url <> path) |> result.map_error(fn(_) { InvalidUrl }),
  )
  let req =
    req
    |> request.set_method(method)
    |> request.set_header("authorization", "Bearer " <> api_key)
    |> request.set_header("accept", "application/json")
    |> request.set_query(query)
  let req = case body {
    Some(body) ->
      req
      |> request.set_header("content-type", "application/json")
      |> request.set_body(json.to_string(body))
    None -> req
  }
  use resp <- result.try(httpc.send(req) |> result.map_error(HttpError))
  validate_response(resp)
}

fn validate_response(resp: response.Response(String)) -> Result(Response, Error) {
  let response.Response(status:, body:, ..) = resp
  case status >= 200 && status < 300 {
    True -> Ok(Response(status: status, body: body, data: decode_dynamic(body)))
    False -> Error(ApiError(status: status, body: body))
  }
}

fn decode_dynamic(body: String) -> Option(Dynamic) {
  case body == "" {
    True -> None
    False ->
      case json.parse(body, using: decode.dynamic) {
        Ok(data) -> Some(data)
        Error(_) -> None
      }
  }
}
