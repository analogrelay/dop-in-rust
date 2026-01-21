# HTTP Pipeline, but with ECS flair

If you've worked on an SDK that makes HTTP requests, you know the complexity: retries, timeouts, endpoint selection, request signing, logging. Let's see how DOP shapes this design.

---

## The OOP Approach: Handler Chains

In C#, you might build a pipeline with delegating handlers:

```csharp
// C# - HttpClient handler chain
public class RetryHandler : DelegatingHandler {
    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken ct) 
    {
        // Handler owns retry state, logging, configuration...
        for (int i = 0; i < 3; i++) {
            var response = await base.SendAsync(request, ct);
            if (response.IsSuccessStatusCode) return response;
        }
        throw new Exception("Retries exhausted");
    }
}
```

Each handler is an object with its own state. The request flows through objects calling other objects.

---

## DOP Approach: The ECS Pattern in Disguise

Remember ECS? Entities are just IDs, components hold the data, and systems operate on specific components. The same pattern applies here, but with some simplification because we don't have the large-scale data processing needs a game has:

| ECS Concept | HTTP Pipeline Equivalent |
|-------------|--------------------------|
| Entity | `RequestContext` (just a container) |
| Components | `Request`, `RoutingDecision`, `RetryState` |
| Systems | `select_endpoint`, `add_auth`, `update_retry_state` |

We don't need to store Components in separate arrays for cache efficiency (which incurs a developer experience cost), but we still want to separate data into focused types.

**The key insight: systems operate on components, not entities.** Just like `movement_system` takes `Query<(&mut Position, &Velocity)>` rather than the whole entity, our pipeline functions take specific pieces of the context.

```rust,noplayground
use std::collections::HashMap;
use std::time::Duration;

#[derive(Clone)]
enum Method { Get, Post, Put, Delete }

// COMPONENT: Core request data - the "what" of the request
struct Request {
    method: Method,
    path: String,
    headers: HashMap<String, String>,
    body: Option<Vec<u8>>,
}

// COMPONENT: Routing decision - where the request goes
// This is its own type because routing can be re-decided on retry
enum RoutingDecision {
    Pending,                           // Not yet decided
    Routed { endpoint: String },       // We know where to send it
    Redirect { new_path: String },     // Server told us to go elsewhere
}

// COMPONENT: Retry state - tracking attempt history
// Grouped together because these fields change together
struct RetryState {
    attempt: u32,
    max_attempts: u32,
    last_error: Option<RequestError>,
    backoff: Duration,
}

#[derive(Clone, Debug)]
enum RequestError {
    Timeout,
    ConnectionFailed,
    ServiceUnavailable,
    Throttled { retry_after: Duration },
}

// ENTITY: Just a container that holds components together
// The RequestContext itself has no behavior - it's just an ID for "this request"
struct RequestContext {
    request: Request,
    routing: RoutingDecision,
    retry: RetryState,
}
```

Why structure it this way? **Systems (functions) operate on components, not the entity.** Each function takes only the components it needs:

- `select_endpoint(&RetryState, ...) -> RoutingDecision`
- `add_auth(Request, ...) -> Request`
- `update_retry_state(RetryState, ...) -> RetryState`

In C#, you'd likely have one big mutable object where any method could touch anything. The ECS/DOP approach makes data access explicit.

---

## Pipeline Stages Transform Specific Parts

Each stage is a function that works with just the data it needs:

```rust
use std::collections::HashMap;
use std::time::Duration;

#[derive(Clone)]
enum Method { Get, Post, Put, Delete }

struct Request {
    method: Method,
    path: String,
    headers: HashMap<String, String>,
    body: Option<Vec<u8>>,
}

#[derive(Clone)]
enum RoutingDecision {
    Pending,
    Routed { endpoint: String },
}

#[derive(Clone)]
struct RetryState {
    attempt: u32,
    max_attempts: u32,
    last_error: Option<RequestError>,
    backoff: Duration,
}

#[derive(Clone, Debug)]
enum RequestError {
    Timeout,
    ServiceUnavailable,
    Throttled { retry_after: Duration },
}

struct RequestContext {
    request: Request,
    routing: RoutingDecision,
    retry: RetryState,
}

struct Response {
    status: u16,
    body: Vec<u8>,
}

// Routing stage - ONLY looks at retry state to pick an endpoint
// Takes just what it needs, returns just what it changes
fn select_endpoint(retry: &RetryState, endpoints: &[String]) -> RoutingDecision {
    let idx = retry.attempt as usize % endpoints.len();
    RoutingDecision::Routed { 
        endpoint: endpoints[idx].clone() 
    }
}

// Auth stage - transforms the request headers
// Takes the request, returns a new request with auth added
fn add_auth(mut request: Request, token: &str) -> Request {
    request.headers.insert(
        "Authorization".to_string(), 
        format!("Bearer {}", token)
    );
    request
}

// Retry stage - transforms retry state based on error
// Pure function: error in, new retry state out
fn update_retry_state(mut retry: RetryState, error: RequestError) -> RetryState {
    retry.attempt += 1;
    retry.backoff = match &error {
        RequestError::Throttled { retry_after } => *retry_after,
        _ => retry.backoff * 2,  // Exponential backoff
    };
    retry.last_error = Some(error);
    retry
}

fn send_request(_request: &Request, _routing: &RoutingDecision) -> Result<Response, RequestError> {
    // Simulated - would actually make HTTP call
    Err(RequestError::ServiceUnavailable)
}

fn main() {
    let endpoints = vec![
        "https://cosmos-east.azure.com".to_string(),
        "https://cosmos-west.azure.com".to_string(),
    ];
    
    // Start with initial context
    let mut ctx = RequestContext {
        request: Request {
            method: Method::Get,
            path: "/dbs/mydb/colls/mycoll".to_string(),
            headers: HashMap::new(),
            body: None,
        },
        routing: RoutingDecision::Pending,
        retry: RetryState {
            attempt: 0,
            max_attempts: 3,
            last_error: None,
            backoff: Duration::from_millis(100),
        },
    };
    
    loop {
        println!("Attempt {}", ctx.retry.attempt + 1);
        
        // Each stage transforms just its piece
        ctx.routing = select_endpoint(&ctx.retry, &endpoints);
        ctx.request = add_auth(ctx.request, "secret-token");
        
        match send_request(&ctx.request, &ctx.routing) {
            Ok(response) => {
                println!("Success! Status: {}", response.status);
                break;
            }
            Err(e) => {
                println!("Error: {:?}", e);
                // Transform just the retry state
                ctx.retry = update_retry_state(ctx.retry, e);
                
                if ctx.retry.attempt >= ctx.retry.max_attempts {
                    println!("Retries exhausted after {} attempts", ctx.retry.attempt);
                    break;
                }
            }
        }
    }
}
```

Notice how each function takes **only what it needs**:

- `select_endpoint` needs retry state and endpoints, returns a routing decision
- `add_auth` needs the request, returns a transformed request  
- `update_retry_state` needs current state and error, returns new state

This is ownership in action - you can pass `ctx.retry` to a function without giving it access to `ctx.request`.

---

## The Key DOP Insights

Notice what's different from the C# approach:

**1. Context is composed of focused types**

- `RetryState`, `RoutingDecision`, `Request` are separate types
- Each can be transformed independently
- Related data stays together (retry count + backoff + last error)

**2. Ownership enables narrow function signatures**

- `select_endpoint(&RetryState, &[String]) -> RoutingDecision`
- Functions take only what they need - not the whole context
- The compiler enforces this boundary

**3. Transformations replace, not mutate**

- `ctx.retry = update_retry_state(ctx.retry, error)`
- Old state is consumed, new state takes its place
- No hidden side effects or spooky action at a distance

**4. The type system documents data flow**

- Reading the function signatures tells you what each stage touches
- In C#, any handler could modify any part of the request

**5. Unit testing is trivial**

- `update_retry_state` is a pure function: construct input, assert output
- No mocking frameworks, no dependency injection, no test fixtures
- If it compiles and the test passes, it works

---

## Enums for Request Decisions

The `PipelineResult` enum makes control flow explicit - a pattern you'll use constantly:

```rust
use std::time::Duration;

// What should happen after each stage?
enum PipelineAction {
    // Continue to the next stage
    Continue,
    
    // Retry with a different endpoint
    RetryDifferentEndpoint { reason: String },
    
    // Retry after a delay (e.g., throttling)
    RetryAfterDelay { delay: Duration },
    
    // Request is complete
    Done,
    
    // Unrecoverable failure
    Abort { error: String },
}

fn decide_retry_strategy(status: u16, attempt: u32) -> PipelineAction {
    match (status, attempt) {
        (200..=299, _) => PipelineAction::Done,
        (429, a) if a < 3 => PipelineAction::RetryAfterDelay { 
            delay: Duration::from_secs(1 << a)  // Exponential backoff
        },
        (503, a) if a < 3 => PipelineAction::RetryDifferentEndpoint {
            reason: "Service unavailable".to_string()
        },
        (_, _) => PipelineAction::Abort { 
            error: format!("Failed with status {}", status)
        },
    }
}

fn main() {
    // Test the decision function
    println!("Status 200: {:?}", matches!(decide_retry_strategy(200, 0), PipelineAction::Done));
    println!("Status 429 attempt 1: exponential backoff");
    println!("Status 503 attempt 1: try different endpoint");
    println!("Status 500 attempt 5: abort");
}
```

Compare this to C# where retry logic is often buried in handler implementations. Here, `decide_retry_strategy` is a pure function you can unit test trivially.

---

## Data-Oriented Thinking for SDKs

This pattern scales to complex SDK scenarios:

- **Connection pooling**: Pool state is data, checkout/return are functions
- **Request signing**: Signature computation is a pure function on request data
- **Caching**: Cache is data (HashMap), lookup/store are functions
- **Diagnostics**: Trace context is data that flows through the pipeline

We still use `impl` blocks to group related functions with the data they operate on. But the focus is on **data transformations** rather than object behavior.

The DOP mindset: *What data do I need? What transformations happen to it?*
