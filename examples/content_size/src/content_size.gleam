import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import task_limiter

pub fn main() {
  // A list of URLs to get the returned content byte count.
  let urls = [
    "https://gleam.run", "https://packages.gleam.run",
    "https://github.com/gleam-lang/awesome-gleam",
    "https://github.com/gleam-lang/gleam", "https://tour.gleam.run/everything/",
    "https://gloogle.run/", "https://gleam.unnecessary.tech",
    "https://bsky.app/profile/markholmes.bsky.social/feed/aaacxsnkbbdei",
  ]

  // Create a list of functions that returns tuples of the url queried and its content
  // size in bytes
  list.map(urls, fn(url) { fn() { #(url, get_content_size(url)) } })
  // Run functions 4 at a time with a polling interval of 5 ms.
  |> task_limiter.async_await(4, 5)
  // For each returned value print the url and length, or an error if there was an
  // await error.
  |> list.each(fn(task_return) {
    case task_return {
      Ok(#(url, bytes)) -> io.println(url <> ": " <> int.to_string(bytes))
      Error(_) -> io.println("An await error occurred")
    }
  })
}

// Retrieve the content and return the size in bytes for a url.
// Return 0 if there is an error.
fn get_content_size(url: String) -> Int {
  case get_content(url) {
    Ok(body) -> string.byte_size(body)
    _ -> 0
  }
}

// A simple get content function using httpc
fn get_content(url: String) -> Result(String, Nil) {
  use req <- result.try(request.to(url))

  use resp <- result.map(httpc.send(req) |> result.replace_error(Nil))

  resp.body
}
