# OCaml

While neither the OCaml compiler nor the standard library `Base` provide any support for asynchronous computation, there are external libraries that introduce the functionality into the language. One is `Async`, which comes with Jane Street's `Core` library, another is `Lwt`.

## Async

Since the basic ideas of this library have already been covered in the presentation, their explanation will be kept brief here.

Async does not utilize system threads for parallelization, but rather implements it's own system of non-preemptive user-level threads to handle asynchronous operations. While this means that it does not benefit from the potential increase in performance from utilizing multiple cores, it does avoid the overhead that comes with creating and destroying system threads, while still allowing the user to avoid dead-time when waiting for external responses.

### Deferred

For representing the potentially pending result of an asynchronous computation, Async provides a high-level monadic datatype `Deferred.t`. With monadic composition, either using `Deferred.bind` directly or some syntactic sugar for it, these asynchronous computations can be chained together.

For asynchronous computations to be executed, control has to be handed over to the Async scheduler using `Scheduler.go`.

### Ivar & upon

While `Deferred` provides a high-level way to compose existing asynchronous operations, to implement asynchronous operations from scratch, a low-level interface is provided via `Ivar` and `upon`.

An `Ivar.t` is a variable which represents the actual value behind a Deferred, which can be manually filled at any time, prompting the Deferred to become determined. How and when the Ivar is filled can be arbitrary implemented, allowing for custom asynchronous operations. For this purpose, there also is a function `upon` provided, which allows for scheduling arbitrary non-asynchronous code to be executed once a certain Deferred becomes determined.

As an Example:

```ocaml
module Delayer = struct
  type t = { delay: Time.Span.t;
             jobs: (unit -> unit) Queue.t;
           }

  let create delay =
    { delay; jobs = Queue.create () }

  let schedule t thunk =
    let ivar = Ivar.create () in
    Queue.enqueue t.jobs (fun () ->
      upon (thunk ()) (fun x -> Ivar.fill ivar x));
    upon (after t.delay) (fun () ->
      let job = Queue.dequeue_exn t.jobs in
      job ());
    Ivar.read ivar
end;;
```

This somewhat artificially conceived utility allows for scheduling some asynchronous operations to be executed in order, but after some predefined delay of time. Here, an Ivar is used to back the Deferred that is returned from the `schedule` function. This Ivar is filled once, first, the artificial delay has elapsed (`upon (after t.delay) (...)`), and then, the actual asynchronous operation that has been scheduled has become determined (`upon (thunk ()) (...)`).

The monadic bind operator used to compose asynchronous operations is simply a convenience function that utilizes an IVar and `upon`:

```ocaml
let bind d ~f =
  let i = Ivar.create () in
  upon d (fun x -> upon (f x) (fun y -> Ivar.fill i y));
  Ivar.read i;;
```

## Lwt

Similarly to Jane Street's Async, the Lwt library uses a monadic data type `Lwt.t`, called Promise, to represent the result of asynchronous computation. And while Lwt by default also uses a system of non-preemptive user-level threads, it provides further 