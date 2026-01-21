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
struct Meters(f64);
struct Seconds(f64);

fn main() {
    let distance = Meters(100.0);
    let time = Seconds(9.58);
    
    // At runtime, these are just f64 values
    // No wrapper, no indirection, no cost
}
```

This means you get type safety without sacrificing performance.

---

## Adding Behavior to Newtypes

Newtypes are full-fledged types, so you can implement methods and traits on them:

```rust
struct Temperature(f64);

impl Temperature {
    fn new(celsius: f64) -> Self {
        Temperature(celsius)
    }
    
    fn to_fahrenheit(&self) -> f64 {
        self.0 * 9.0 / 5.0 + 32.0
    }
    
    fn is_freezing(&self) -> bool {
        self.0 <= 0.0
    }
}

fn main() {
    let temp = Temperature::new(-5.0);
    println!("{}°C = {}°F", temp.0, temp.to_fahrenheit());
    println!("Freezing? {}", temp.is_freezing());
}
```

This lets you attach domain-specific logic directly to your types.

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

## The Orphan Rule and Newtypes

One powerful use of newtypes is working around the **orphan rule**. Remember, you can only implement a trait if you own either the trait or the type. What if you want to implement a foreign trait for a foreign type?

Use a newtype to create a local type that wraps the foreign type:

```rust
use std::fmt;

// We can't implement Display for Vec<i32> directly (orphan rule)
// But we can wrap it in a newtype!

struct Comma<T>(Vec<T>);

impl<T: fmt::Display> fmt::Display for Comma<T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut first = true;
        for item in &self.0 {
            if !first {
                write!(f, ", ")?;
            }
            write!(f, "{}", item)?;
            first = false;
        }
        Ok(())
    }
}

fn main() {
    let numbers = Comma(vec![1, 2, 3, 4, 5]);
    println!("{}", numbers);  // Output: 1, 2, 3, 4, 5
}
```

The newtype acts as an adapter, giving you a local type that you can implement traits on.

---

## When to Use Newtypes

Good use cases for newtypes:

- **Distinct IDs**: `UserId`, `OrderId`, `SessionId` - prevent mixing different kinds of IDs
- **Units**: `Meters`, `Seconds`, `Bytes` - encode units in the type system
- **Validation**: Wrap types that should only be constructed through validation (by keeping the inner field private)
- **Semantic meaning**: `Email`, `PhoneNumber`, `Url` - more expressive than `String`
- **Orphan rule workaround**: Implement foreign traits for foreign types

```rust
pub struct Email(String);  // Private field - can't construct directly

impl Email {
    pub fn new(email: String) -> Option<Self> {
        if email.contains('@') {
            Some(Email(email))
        } else {
            None
        }
    }
    
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

fn send_email(email: &Email) {
    println!("Sending to: {}", email.as_str());
}

fn main() {
    if let Some(email) = Email::new(String::from("alice@example.com")) {
        send_email(&email);  // Can only pass validated emails!
    }
    
    // Email(String::from("invalid"));  // ERROR: tuple struct constructor is private
}
```

By keeping the inner field private (the default for tuple struct fields when declared in a module), you ensure that `Email` can only be created through the `new` constructor, which validates the input.

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
