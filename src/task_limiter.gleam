import gleam/list
import gleam/otp/task
import gleam/pair

/// Run a set of functions asynchronously as OTP task num at a time, then
/// waits for the value computed by the tasks to return. Every interval
/// milliseconds the running jobs are checked to see if they have completed
/// and new jobs from the queue are started.
///
/// **Note**: The values are returned in an arbitrary order.
pub fn async_await(
  work: List(fn() -> a),
  num: Int,
  interval: Int,
) -> List(Result(a, task.AwaitError)) {
  let #(run_group, wait_group) = list.split(work, num)

  let running = run_group |> list.map(task.async)
  run_helper(running, wait_group, [], interval)
}

fn run_helper(
  running: List(task.Task(a)),
  waiting: List(fn() -> a),
  done: List(Result(a, task.AwaitError)),
  timeout: Int,
) -> List(Result(a, task.AwaitError)) {
  case running {
    [] -> done
    _ -> {
      let results = task.try_await_all(running, timeout) |> list.zip(running)

      let #(finished, working) =
        results
        |> list.partition(fn(tup) {
          case tup {
            #(Error(task.Timeout), _) -> False
            _ -> True
          }
        })

      let finished_result =
        finished
        |> list.map(pair.first)

      let working_tasks =
        working
        |> list.map(pair.second)

      let n_to_add = list.length(finished)
      let #(to_add, new_waiting) = list.split(waiting, n_to_add)

      run_helper(
        list.append(to_add |> list.map(task.async), working_tasks),
        new_waiting,
        list.append(finished_result, done),
        timeout,
      )
    }
  }
}
