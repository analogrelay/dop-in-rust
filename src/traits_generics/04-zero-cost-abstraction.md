# Zero-Cost Abstraction

Rust's generics and trait system enable one of the language's core principles: **zero-cost abstraction**. This means you can write high-level, abstract code without paying any runtime performance penalty compared to hand-written, concrete code.

The key mechanism is **monomorphization**, which we introduced in the [Generics and Bounds](./02-generics-bounds.md) chapter. The compiler generates specialized versions of generic code for each concrete type you use, allowing full optimization as if you'd written separate functions by hand.

---

## The Zero-Cost Promise

In C#, abstraction often comes with overhead:

```csharp
// C# - Using an interface incurs virtual dispatch overhead
void Process(IEnumerable<int> items) {
    foreach (var item in items) {
        // Virtual method call per iteration
    }
}
```

In Rust, abstractions built on traits and generics compile down to direct code:

```rust
fn process<I: Iterator<Item = i32>>(items: I) {
    for item in items {
        // Direct call, fully inlined - no overhead
    }
}
```

The generic function is as fast as if you'd written the code specifically for the concrete type.

---

## Closures: Zero-Cost Function Objects

In C#, closures capture variables and create heap-allocated objects. In Rust, closures using `impl Fn` traits are typically zero-cost - they're often inlined completely.

```rust
fn apply_to_all<F>(values: &mut [i32], operation: F)
where
    F: Fn(i32) -> i32,
{
    for value in values {
        *value = operation(*value);
    }
}

fn main() {
    let mut numbers = vec![1, 2, 3, 4, 5];
    let multiplier = 10;
    
    // The closure captures 'multiplier', but there's no heap allocation
    apply_to_all(&mut numbers, |x| x * multiplier);
    
    println!("{:?}", numbers);  // [10, 20, 30, 40, 50]
}
```

When the compiler monomorphizes `apply_to_all` for this specific closure, it generates code equivalent to:

```rust
// Compiler-generated specialized version
fn apply_to_all_specialized(values: &mut [i32], multiplier: i32) {
    for value in values {
        *value = *value * multiplier;  // Inlined directly
    }
}
```

The closure's code is injected directly at the call site. There's no function pointer, no vtable lookup, no heap allocation - just direct, inlined code.

### The Three Closure Traits

Rust has three closure traits, each representing different levels of captured variable usage:

- `FnOnce`: Can be called once, may consume captured variables
- `FnMut`: Can be called multiple times, may mutate captured variables
- `Fn`: Can be called multiple times, only reads captured variables

All three support zero-cost abstraction through monomorphization.

```rust
fn process_batch<F>(items: &mut [i32], mut operation: F)
where
    F: FnMut(i32) -> i32,
{
    for item in items {
        *item = operation(*item);
    }
}

fn main() {
    let mut numbers = vec![1, 2, 3, 4, 5];
    let mut counter = 0;
    
    // This closure mutates 'counter', so it implements FnMut
    process_batch(&mut numbers, |x| {
        counter += 1;
        x + counter
    });
    
    println!("{:?}", numbers);  // [2, 4, 6, 8, 10]
    println!("Processed {} items", counter);  // 5
}
```

---

## Iterator Chains: Zero-Cost Composition

One of Rust's most impressive zero-cost abstractions is iterators. Complex iterator chains compile down to simple loops with no intermediate allocations.

```rust
fn main() {
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    
    let sum: i32 = numbers
        .iter()
        .filter(|&&x| x % 2 == 0)  // Keep even numbers
        .map(|&x| x * x)            // Square them
        .sum();                     // Add them up
    
    println!("Sum of squares of even numbers: {}", sum);  // 220
}
```

This high-level, functional code compiles to something equivalent to:

```rust
fn main() {
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    
    let mut sum = 0;
    for &x in &numbers {
        if x % 2 == 0 {
            let squared = x * x;
            sum += squared;
        }
    }
    
    println!("Sum of squares of even numbers: {}", sum);  // 220
}
```

No intermediate vectors, no heap allocations, no function call overhead. The iterator adapters (`filter`, `map`) are **lazy** - they don't do any work until consumed by `sum()`. When monomorphized, the entire chain becomes a single tight loop.

### More Complex Chains

Even deeply nested iterator operations maintain zero cost:

```rust
struct Player {
    name: String,
    score: i32,
    active: bool,
}

fn main() {
    let players = vec![
        Player { name: "Alice".to_string(), score: 100, active: true },
        Player { name: "Bob".to_string(), score: 50, active: false },
        Player { name: "Carol".to_string(), score: 150, active: true },
        Player { name: "Dave".to_string(), score: 75, active: true },
    ];
    
    let top_active_players: Vec<&str> = players
        .iter()
        .filter(|p| p.active)                    // Only active players
        .filter(|p| p.score > 70)                // Score above 70
        .map(|p| p.name.as_str())                // Extract names
        .collect();                              // Collect into vector
    
    println!("Top active players: {:?}", top_active_players);
}
```

Despite looking like multiple passes over the data, this compiles to a single loop that applies all the checks and transformations inline.

---

## Async/Await: Zero-Cost When Synchronous

Rust's async/await is designed as a zero-cost abstraction. When operations complete synchronously (don't need to yield control), there's no overhead compared to regular synchronous code.

```rust
async fn fetch_data() -> String {
    // If this completes immediately, there's no async overhead
    "data".to_string()
}

async fn process() -> String {
    let data = fetch_data().await;
    format!("Processed: {}", data)
}
```

When an async function completes without actually yielding (blocking), it's as efficient as calling a regular function. The async machinery only kicks in when actual waiting is needed.

### State Machines Under the Hood

Rust transforms async functions into state machines at compile time:

```rust
async fn download_and_process(url: &str) -> Result<String, String> {
    let data = download(url).await?;  // Might yield here
    let processed = process_data(data);  // Synchronous work
    Ok(processed)
}

async fn download(_url: &str) -> Result<String, String> {
    Ok("downloaded".to_string())
}

fn process_data(data: String) -> String {
    data.to_uppercase()
}
```

The compiler generates a state machine that can suspend and resume. If `download()` completes immediately, the entire function runs without any async overhead. The abstraction is free when the fast path is taken.

---

## The Trade-Off: Compile Time vs Runtime

Zero-cost abstraction isn't actually "free" - it shifts costs from runtime to compile time:

| Aspect | Zero-Cost Abstraction | Traditional Abstraction |
|--------|----------------------|-------------------------|
| Runtime performance | As fast as hand-written | May have overhead |
| Binary size | Larger (code duplication) | Smaller (code reuse) |
| Compile time | Slower (more codegen) | Faster |
| Optimization potential | Maximum (compiler sees concrete types) | Limited (runtime dispatch) |

Monomorphization means the compiler generates specialized code for each type combination you use. This takes time and produces more machine code, but results in optimal runtime performance.

```rust
fn print_many<T: std::fmt::Display>(items: &[T]) {
    for item in items {
        println!("{}", item);
    }
}

fn main() {
    print_many(&[1, 2, 3]);           // Generates print_many::<i32>
    print_many(&["a", "b", "c"]);     // Generates print_many::<&str>
    print_many(&[1.5, 2.5, 3.5]);     // Generates print_many::<f64>
}
```

Three separate versions of `print_many` exist in the final binary, each fully optimized for its specific type.

---

## When Zero-Cost Matters Most

Zero-cost abstractions are particularly valuable when:

1. **Performance-critical code** - Game loops, data processing pipelines, hot paths
2. **Generic libraries** - Library code that works with many types while maintaining performance
3. **Embedded systems** - Where you need abstractions but can't afford runtime overhead
4. **Predictable performance** - No hidden costs, no surprises

```rust
// A zero-cost abstraction for game entities
trait Drawable {
    fn draw(&self);
}

struct Sprite { x: i32, y: i32 }
struct Text { content: String }

impl Drawable for Sprite {
    fn draw(&self) { println!("Drawing sprite at ({}, {})", self.x, self.y); }
}

impl Drawable for Text {
    fn draw(&self) { println!("Drawing text: {}", self.content); }
}

fn render_frame<T: Drawable>(entities: &[T]) {
    for entity in entities {
        entity.draw();  // Direct call, fully inlined
    }
}

fn main() {
    let sprites = vec![
        Sprite { x: 10, y: 20 },
        Sprite { x: 30, y: 40 },
    ];
    
    render_frame(&sprites);  // Monomorphized for Sprite
    
    let texts = vec![
        Text { content: "Score: 100".to_string() },
    ];
    
    render_frame(&texts);  // Separate monomorphization for Text
}
```

In a game running at 60 FPS, having zero overhead in the rendering loop makes a real difference.

---

## The Mental Model

**C# thinking**: "Abstractions (interfaces, generics, LINQ) make code cleaner but I need to watch for performance impact. I might need to avoid abstractions in hot code paths."

**Rust thinking**: "Abstractions built on traits and generics are free. I can write clean, high-level code and trust the compiler to optimize it. The cost is paid at compile time, not runtime."

Zero-cost abstraction is what makes Rust unique: you get the expressiveness of high-level languages with the performance of low-level languages. Write once, optimize everywhere.
