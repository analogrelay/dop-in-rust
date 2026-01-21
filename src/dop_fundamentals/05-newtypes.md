# Newtypes

A **newtype** ([a term that originates from the Haskell functional programming language](https://wiki.haskell.org/Newtype)) is a single-field tuple struct that wraps another type. It's one of Rust's most powerful patterns for creating richer, more expressive types.

```rust
struct UserId(u64);
struct PostId(u64);
struct Timestamp(u64);

fn main() {
    let user = UserId(42);
    let post = PostId(123);
    
    // These are distinct types, even though both wrap u64
    // let wrong: UserId = post;  // ERROR: mismatched types
}
```

---

## Why Newtypes?

In many systems, you'll have multiple concepts that share the same underlying representation but have different semantic meanings. Without newtypes, it's easy to mix them up:

```rust
// Without newtypes - easy to confuse!
fn get_user(user_id: u64) -> String { 
    format!("User {}", user_id) 
}

fn get_post(post_id: u64) -> String { 
    format!("Post {}", post_id) 
}

fn main() {
    let user_id = 42;
    let post_id = 123;
    
    // Oops! Passed the wrong ID - compiler can't help
    println!("{}", get_user(post_id));  // Compiles but wrong!
}
```

With newtypes, the type system catches this mistake:

```rust
struct UserId(u64);
struct PostId(u64);

fn get_user(user_id: UserId) -> String { 
    format!("User {}", user_id.0) 
}

fn get_post(post_id: PostId) -> String { 
    format!("Post {}", post_id.0) 
}

fn main() {
    let user_id = UserId(42);
    let post_id = PostId(123);
    
    println!("{}", get_user(user_id));  // Correct
    // println!("{}", get_user(post_id));  // ERROR: expected UserId, found PostId
}
```

The `.0` syntax accesses the first (and only) field of the tuple struct.

---

## Zero-Cost Abstraction

Newtypes are a **zero-cost abstraction** - they exist only at compile time for type checking. At runtime, they compile down to the inner type with no overhead:

```rust
use std::mem::size_of;

struct Meters(f64);
struct Seconds(f64);

fn main() {
    let distance = Meters(100.0);
    let time = Seconds(9.58);
    
    // At runtime, these are just f64 values
    // No wrapper, no indirection, no cost
    println!("Size of f64: {} bytes", size_of::<f64>());
    println!("Size of Meters: {} bytes", size_of::<Meters>());
    println!("Size of Seconds: {} bytes", size_of::<Seconds>());
    // All print: 8 bytes
}
```

This means you get type safety without sacrificing performance.

---

## Adding Behavior to Newtypes

Newtypes are full-fledged types, so you can implement methods and traits on them:

```rust
struct Celsius(f64);
struct Fahrenheit(f64);

impl Celsius {
    fn new(temp: f64) -> Self {
        Celsius(temp)
    }
    
    fn into_fahrenheit(self) -> Fahrenheit {
        Fahrenheit(self.0 * 9.0 / 5.0 + 32.0)
    }
}

impl Fahrenheit {
    fn new(temp: f64) -> Self {
        Fahrenheit(temp)
    }
    
    fn into_celsius(self) -> Celsius {
        Celsius((self.0 - 32.0) * 5.0 / 9.0)
    }
}

fn main() {
    let temp_c = Celsius::new(-5.0);
    let temp_f = temp_c.into_fahrenheit();
    println!("-5°C = {}°F", temp_f.0);
    
    let temp_f2 = Fahrenheit::new(98.6);
    let temp_c2 = temp_f2.into_celsius();
    println!("98.6°F = {}°C", temp_c2.0);
}
```

This lets you attach domain-specific logic directly to your types, and prevents mixing different units.

---

## Deriving Traits

You can derive standard traits to make newtypes more ergonomic:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct Score(i32);

use std::collections::HashMap;

fn main() {
    let user1 = UserId(1);
    let user2 = UserId(2);
    
    // Can use in collections
    let mut scores = HashMap::new();
    scores.insert(user1, Score(100));
    scores.insert(user2, Score(250));
    
    // Can compare
    println!("User 1 score: {:?}", scores.get(&user1));
    
    let s1 = Score(100);
    let s2 = Score(200);
    println!("Higher score: {:?}", s1.max(s2));
}
```

---

## When to Use Newtypes

Good use cases for newtypes:

- **Distinct IDs**: `UserId`, `OrderId`, `SessionId` - prevent mixing different kinds of IDs
- **Units**: `Meters`, `Seconds`, `Bytes` - encode units in the type system
- **Validation**: Wrap types that should only be constructed through validation (by keeping the inner field private)
- **Semantic meaning**: `Email`, `PhoneNumber`, `Url` - more expressive than `String`
- **Orphan rule workaround**: Implement foreign traits for foreign types (we'll talk about that later)

---

## Transparent Newtypes

Sometimes you want the newtype to have the exact same memory layout as the inner type. The `#[repr(transparent)]` attribute guarantees this:

```rust
#[repr(transparent)]
struct Seconds(f64);

fn main() {
    let time = Seconds(3.14);
    // The memory layout is guaranteed to be identical to f64
}
```

This attribute ensures that the newtype has the same memory representation as its inner type, enabling safe transmutation between them. This is particularly useful for FFI (Foreign Function Interface) where you need to pass Rust types to C functions but want the type safety of newtypes in your Rust code.

Without `#[repr(transparent)]`, the compiler might add padding or change the layout. With it, you're guaranteed that `Seconds` and `f64` are layout-compatible.

---

## The Pattern

Newtypes embody data-oriented thinking: **use the type system to capture domain invariants**. Instead of relying on conventions ("this u64 is always a user ID"), encode that directly in the type. The compiler becomes your ally in preventing bugs.

In C#, you might use interfaces, base classes, or lots of defensive checks. In Rust, you use newtypes to create lightweight, zero-cost, compiler-enforced distinctions between semantically different data.
