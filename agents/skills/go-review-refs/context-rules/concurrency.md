# Context Rules: Concurrency Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| `go func` or `go methodCall` | Entire file containing the goroutine | Use File Access instructions from your prompt | Understand goroutine lifecycle — is there a done channel, context, WaitGroup? |
| `sync.Mutex` or `sync.RWMutex` field in struct | All methods of that struct | Use File Access instructions from your prompt | Check lock ordering across methods — detect deadlock potential |
| Write to map or slice from multiple goroutines | All functions writing to the same variable | Search repo for variable name, then use File Access instructions | Verify synchronization — maps are not goroutine-safe |
| `sync.WaitGroup` | Full function + goroutines it spawns | Use File Access instructions from your prompt | Check Add/Done/Wait balance — Add must happen before goroutine starts |
| Channel creation (`make(chan ...)`) | Full function and all readers/writers of the channel | Use File Access instructions from your prompt | Check for deadlock: unbuffered channel with single goroutine, or nobody reads |
| HTTP handler modifying package-level variable | Package-level var declaration + all handlers | Use File Access instructions from your prompt | Each HTTP handler runs in its own goroutine — shared state needs sync |
| `select` statement | All cases and the channel sources | Use File Access instructions from your prompt | Check for missing `default` or missing `ctx.Done()` case |
| Loop variable used in goroutine (pre-Go 1.22) | go.mod for Go version | Use File Access instructions from your prompt | If Go < 1.22, loop var capture is a race condition |
| `sync.Once` | Full file — check what `Do()` executes | Use File Access instructions from your prompt | If Do() can fail, error is swallowed on retry — verify initialization safety |
| `sync.Once` where "already started" / "initialized" is tracked by a local variable set inside the `Do` closure (vs. a field on the receiver or `atomic.Bool`) | Full function + the method's type declaration | Use File Access instructions from your prompt | Concurrent first caller that did not run the closure observes stale `false` and reports a spurious "called more than once" / "not initialized" |
| `atomic.` (sync/atomic operations) | All access sites for the same variable | Search repo for variable name, then use File Access instructions | Mixed atomic/non-atomic access is a data race — ALL access must be atomic |
| Long-running goroutine started from `Invoke`/`fx.Invoke`/module init | Application lifecycle / shutdown registration site | Search repo for `lifecycle.Append` / `fx.Hook` / `OnStop`, then use File Access instructions | Verify a shutdown hook stops the goroutine and drains in-flight work on SIGTERM |
| Consumer/subscriber loop (`Subscribe`, `Consume`, `PullMessages`) or new HTTP/gRPC server (`ListenAndServe`, `Serve`) | Shutdown path — how does it stop? | Use File Access instructions from your prompt | Verify `Shutdown(ctx)`/drain/ack flush before exit |
| `time.NewTicker` / `time.NewTimer` in a long-running goroutine | Full function; search for matching `Stop()` | Use File Access instructions from your prompt | Verify `defer t.Stop()` and shutdown path stops the ticker goroutine |
