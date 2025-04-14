import gleam/erlang/process
import gleam/list
import gleam/order
import gleam/time/duration
import gleam/time/timestamp
import gleeunit
import gleeunit/should
import task_limiter

pub fn main() {
  gleeunit.main()
}

// Test that running two tasks sequentially actually runs one at a time.
pub fn two_tasks_sequentially_test() {
  let tasks =
    list.range(1, 2)
    |> list.map(fn(_) {
      fn() {
        process.sleep(10)
        True
      }
    })

  let start = timestamp.system_time()
  task_limiter.async_await(tasks, 1, 1)
  let end = timestamp.system_time()

  timestamp.difference(start, end)
  |> duration.compare(duration.milliseconds(19))
  |> should.equal(order.Gt)
}

// Test that running two tasks sequentially actually runs one at a time.
pub fn two_tasks_simultaneously_test() {
  let tasks =
    list.range(1, 2)
    |> list.map(fn(_) {
      fn() {
        process.sleep(10)
        True
      }
    })

  let start = timestamp.system_time()
  task_limiter.async_await(tasks, 2, 1)
  let end = timestamp.system_time()

  timestamp.difference(start, end)
  |> duration.compare(duration.milliseconds(19))
  |> should.equal(order.Lt)
}
