# task_limiter

[![Package Version](https://img.shields.io/hexpm/v/task_limiter)](https://hex.pm/packages/task_limiter)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/task_limiter/)

```sh
gleam add task_limiter@1
```

Spawn Gleam OTP tasks N at a time rather than all at once. Useful for limiting
the number of HTTP client requests that are made at one time for web sites that
are touchy about getting hundreds of requests at a time.

The example below shows how to query a list of URLs limiting the queries to
4 at a time. The full example is in [examples/content_size](examples/content_size).

```gleam
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
```

Further documentation can be found at <https://hexdocs.pm/task_limiter>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
