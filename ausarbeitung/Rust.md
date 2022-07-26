# Rust

While Rust provides as part of it's compiler implementation and it's standard library a framework for encoding asynchronous tasks, it does not provide a runtime to execute these tasks. Therefore, while the core principles of asynchronous execution are defined by Rust itself, the details of how async tasks are executed is defined independently by different libraries.

## Future

```rust
pub trait Future {
    type Output;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output>;
}
```

Provided as a trait by the Rust standard library, a _Future_ represents an asynchronous computation that either is done, providing a final result value of the computation, or is still pending, needing to make further progress.

To invoke progress to be made on a Future, it has to be _polled_, which can either result in the Future completing it's computation, returning the final value, or in the Future suspending it's computation, registering a wakeup function that is passed in via the calling context (`cx`) to be called once the Future is ready to be polled again for further progress.

Any `struct` implementing Future therefore has to define in it's `poll` both what computation in to be done to further it's progress in computing it's final value, and, if not complete, by what means the wakeup callback is to be called back to signify to the runtime that the Future can be polled again.

When and how any Future is polled is not defined by the Rust standard library, but instead rather can be handled by different external runtimes.

## Syntax

To simply declaration and synchronization of asynchronous tasks, the Rust compiler, since the 2018 edition, provides some built-in syntax.

### Async & Await

Manually constructing the necessary `struct` and implementing `Future` for it for every piece of asynchronous code is tedious, error prone and redundant. Therefore, the Rust compiler provides a way to declare async functions, closures and code blocks using the special keyword `async`, from which during compilation the necessary implementation of `Future` is generated.

Similarly, instead of manually dealing with contexts and polling a Future directly, a keyword `await` is provided by the Rust compiler to wait for a Future to conclude and extract it's resulting value.

```rust
async fn foo() -> u8 { 5 }

fn bar() -> impl Future<Output = u8> {
    async {
        let x: u8 = foo().await;
        x + 5
    }
}
```

The code inside the async function, closure or code block will become the computation that is to be done to further the computation of the Future it compiles to, wherein any `await` will become a point from which computation will be resumed when the asynchronous task that is being awaited concludes. For this, any data necessary to continue further computation will be stored in the implicitly generated struct that represents our Future.

This combination of `async` and `await` allows us write and compose asynchronous functions, closures and code blocks in simple and general, runtime-independent manner.

**((Define exactly what `async` and `await` do in hard technical terms or even code))**

### Join

While we can dispatch and wait for a single asynchronous task with `await`, if we want to dispatch multiple asynchronous tasks at once, awaiting each in turn will not suffice, since the execution of the calling async context will be suspended with the first `await`, therefore resulting in the second asynchronous task to be initiated only once the first one has concluded, &c. This means, that the asynchronous tasks will not be dispatched simultaneously, but rather each in sequence, unnecessarily leaving performance that could be gained with an asynchronous execution model on the table.

```rust
async fn one() -> usize { 1 }
async fn two() -> usize { 2 }

async fn in_sequence() {
    let x = one().await;
    let y = two().await;
    assert_eq!((x, y), (1, 2));
}
```

To remedy this, the Rust standard library provides a macro for joining up multiple Futures, such that they are polled together when awaited.

```rust
async fn one() -> usize { 1 }
async fn two() -> usize { 2 }

async fn in_sequence() {
    let (x,y) = join!(one(),two()).await;
    assert_eq!((x, y), (1, 2));
}
```

## Runtime

The Rust standard library does not provide an async runtime, meaning that while we can readily declare and compose async functions, we can not actually execute any asynchronous code without the use of an external library.

### Tokio

...