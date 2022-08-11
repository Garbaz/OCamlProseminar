# Haskell

All side-effecting computation in Haskell are represented via the monad `type IO a = World -> (a, World)`, where `World` stands for a theoretical type that represents the entirety of the persistent outside world to our program. A value of this monad therefore stands for an action that transforms the current state of the world in some way (e.g. write to a file) and produces some internal result of type `a` (e.g. the result of reading a file). These actions can be sequentially composed with the monad operators `>>= :: IO a -> (a -> IO b) -> IO b` and the `>> :: IO a -> IO b -> IO b`.

For an action represented by the IO monad (which might consist of any number of chained together actions) to be actually executed and the side-effects they represent to occur, we assign this action to the special label `main :: IO ()`. E.g.:

```haskell
main :: IO ()
main = getLine >>= \l -> putStr l
```

Here `getLine :: IO String` and `putStr :: String -> IO ()` are IO actions provided by the standard library, which in turn are implemented with simpler IO actions, down to a set of primitive IO actions that actually have to interact with Haskell-external non-pure systems, e.g. the kernel.

Notably this representation of side-effects through the chaining of IO actions deliberately considers the world and our actions upon it as strictly sequential. While there is no guarantee what effects our actions will have, it is guaranteed by Haskell that these actions happen in exactly the order specified. This is generally desired and a necessary distinction from normal lazy evaluation in Haskell, providing us the ability to declare precedence between our actions that is needed, and unknown to the Haskell compiler, for correct interaction with the outside world (e.g. we can't receive a response before sending a query). However this strict ordering is fundamentally incompatible with concurrency, where we would explicitly like for actions to possibly happen in independent arbitrary order to facilitate asynchronous computation.

## Concurrent Haskell

For this, an extension to both the language of Haskell and in turn the semantics of `IO` is provided with `forkIO :: IO () -> IO ThreadId`. `forkIO` takes an IO action and causes it to be executed concurrently to the parent thread from which it was called. Importantly, this means that whatever IO action is passed to `forkIO` will no longer be executed in the ordered specified by the chain of IO actions of the parent thread. Any subsequent IO actions performed by the parent thread will be arbitrarily interleaved with IO actions performed by the child thread. The ordering of IO actions is only guaranteed internal to each thread respectively. For example:

```haskell
forkIO (forever (putChar '1')) >> forever (putChar '0')
```

This will print an arbitrary mix of 0s and 1s to the output, with no determined order to them.

## Cross-thread communication with MVar

While `forkIO` allows to spawn a child thread to do IO actions on it's own, once forked, there is no way for the parent thread and child thread to communicate, neither can any two child thread communicate with each other. This is remedied by the introduction of `data MVar a`, a possibly empty mutable location that is safely synchronized between threads. An `MVar` is created with `newEmptyMVar :: IO (MVar a) ` or `newMVar :: a -> IO (MVar a)`, can be written to with `putMVar :: MVar a -> a -> IO ()` and read from with `takeMVar :: MVar a -> IO a`. These latter two operations each block, `putMVar` waiting for the `MVar` to become empty, before writing to it, leaving it full, and `takeMVar` waiting for the `MVar` to become filled before reading it, leaving it empty. E.g.:

```haskell
do
  v <- newEmptyMVar
  forkIO (threadDelay 1000000 >> putMVar v "momentous result")
  m <- takeMVar v
  print m
```

This will cause the parent thread to wait for the child thread to fill `v`, before printing the result that has been handed back to it.

## Async in Haskell

While `forkIO` provides a very general way for concurrent execution in Haskell, it has, as perhaps noticeable above, three properties that we would like to abstract over for asynchronous computation.

The first being, that the IO action we are forking does not have any result, the argument to `forkIO` being of type `IO ()`. Instead, to hand back a possible result to our parent thread, we have to manually create an `MVar` in the parent thread and capture it in the forked IO action for the child to be able to hand back a result. 

The second being that the child thread can silently crash with an exception and leave our parent thread running none the wiser.

And the third being that, once spawned, our child thread might run indefinitely, even after our parent thread is gone, since it's execution becomes entirely independent of the parent.

All of these concerns are alleviated by the thin abstraction over concurrent Haskell provided by `data Async a`.

An asynchronous thread is forked from the parent thread with `async :: IO a -> IO (Async a)`, and the parent thread can wait for the child thread to conclude it's computation with `wait :: Async a -> IO a`. If an exception occurs in the child thread, `wait` will cause this exception to be re-thrown in the parent thread, preventing silently unhandled exceptions. E.g.:

```haskell
do
  a1 <- async (getURL url1)
  a2 <- async (getURL url2)
  page1 <- wait a1
  page2 <- wait a2
  print page1
  print page2
```

Notably, the child thread executing the IO action handed to `async` will be started right away, and not just when awaited. Therefore, waiting first for `a1` and then `a2`, contrary to e.g. `await` in Rust, does not result in the execution of the second asynchronous operation to be delayed until the first concludes, but rather they will be truly executed concurrently, even when awaited sequentially.

Unfortunately this also means that, while we have fulfilled both the first and second wish above, if used in this style, the third issue is still standing; Any child threads will keep running, even if the parent thread dies, since the execution of the child thread does not depend on the parent thread to be waiting for it. This usually is unwanted. Therefore, the function `withAsync :: IO a -> (Async a -> IO b) -> IO b` is provided, which will asynchronously run the given IO action and hand the `Async` into the given function, while also keeping track of the child thread that has been forked off, and killing it when this function returns or throws an exception, ensuring that no orphaned child thread is left running. E.g.:

```haskell
withAsync (getURL url1) $ \a1 -> do
  withAsync (getURL url2) $ \a2 -> do
    page1 <- wait a1
    page2 <- wait a2
    print page1
    print page2
```

Abstracting again over `withAsync`, a few high-level utilities are provided, like `concurrently :: IO a -> IO b -> IO (a, b)` or `race :: IO a -> IO b -> IO (Either a b)`. Using `concurrently`, the above example can be rewritten as:

```haskell
do
  (page1, page2) <- concurrently (getURL url1) (getURL url2)
  print page1
  print page2
```

`race` provides the possibility not to wait for both of two asynchronous operations to conclude, but rather to wait for either to conclude and the other to subsequently be canceled. E.g.:

```haskell
do
  r <- race (getURL url1) (getURL url2)
  case r of
    Left page -> print page
    Right page -> print page
```

Here we will end up printing whichever page is retrieved faster.

## Runtime

The concurrency model of Haskell is entirely abstract and does not specify in any manner how the parallel execution of it's threads is facilitated at runtime. It is therefore up to the design of the compiler how concurrency is implemented.

In the Glasgow Haskell Compiler (GHC), concurrent threads are represented by as system of internal lightweight threads which are preemptively scheduled by a custom scheduler. By default, this occurs entirely on one system thread, but an option is provided for utilizing multiple CPU cores via SMP parallelism.

## References

- https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/mark.pdf
- https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.47.7494&rep=rep1&type=pdf
- https://hackage.haskell.org/package/async-2.2.4/docs/Control-Concurrent-Async.html
- https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/using-concurrent.html
- https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/rts/scheduler