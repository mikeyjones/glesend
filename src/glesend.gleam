pub type Client {
  Client(api_key: String, base_url: String)
}

/// Creates a client configured with the default Resend API base URL.
pub fn new(api_key api_key: String) -> Client {
  Client(api_key: api_key, base_url: "https://api.resend.com")
}

/// Returns a copy of the client that sends requests to the given base URL.
pub fn with_base_url(client: Client, base_url: String) -> Client {
  let Client(api_key:, ..) = client
  Client(api_key: api_key, base_url: base_url)
}
