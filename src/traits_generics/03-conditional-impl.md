# Conditional Implementations

One of Rust's most powerful features: you can implement traits *conditionally*, based on what capabilities the type parameters have.

---

## Implementing for Generic Types

When you have a generic struct, you can add implementations that only apply when the type parameter meets certain bounds:

```rust
use std::fmt::Display;

struct Container<T> {
    value: T,
}

// This impl exists for ALL Container<T>
impl<T> Container<T> {
    fn new(value: T) -> Self {
        Container { value }
    }
    
    fn into_inner(self) -> T {
        self.value
    }
}

// This impl ONLY exists when T implements Display
impl<T: Display> Container<T> {
    fn print(&self) {
        println!("Container holds: {}", self.value);
    }
}

fn main() {
    let int_container = Container::new(42);
    int_container.print();  // Works: i32 implements Display
    
    let string_container = Container::new(String::from("hello"));
    string_container.print();  // Works: String implements Display
    
    // Vec<i32> implements Display, so this works too
    let vec_container = Container::new(vec![1, 2, 3]);
    // vec_container.print();  // ERROR: Vec<i32> doesn't implement Display
    
    // But we can still use methods that don't require Display
    let values = vec_container.into_inner();
    println!("{:?}", values);
}
```

---

## Blanket Implementations

The standard library uses this pattern extensively. For example:

```rust
// In the standard library (simplified):
// impl<T: Display> ToString for T {
//     fn to_string(&self) -> String {
//         format!("{}", self)
//     }
// }
```

This means: "For ANY type that implements `Display`, automatically implement `ToString`."

```rust
use std::fmt::Display;

struct Player {
    name: String,
    health: i32,
}

impl Display for Player {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} ({}hp)", self.name, self.health)
    }
}

fn main() {
    let player = Player { 
        name: String::from("Alice"), 
        health: 100 
    };
    
    // We get ToString for free because we implemented Display!
    let s: String = player.to_string();
    println!("{}", s);
}
```

---

## Building Capability Through Composition

This pattern lets capabilities compose automatically:

```rust
trait Damageable {
    fn health(&self) -> i32;
}

trait Named {
    fn name(&self) -> &str;
}

// Any type that is both Named and Damageable gets a status message
trait HasStatus: Named + Damageable {
    fn status(&self) -> String {
        format!("{}: {} health", self.name(), self.health())
    }
}

// Blanket implementation: anything that's Named + Damageable gets HasStatus
impl<T: Named + Damageable> HasStatus for T {}

struct Player {
    name: String,
    health: i32,
}

impl Named for Player {
    fn name(&self) -> &str { &self.name }
}

impl Damageable for Player {
    fn health(&self) -> i32 { self.health }
}

// Player automatically implements HasStatus!

fn main() {
    let player = Player { 
        name: String::from("Alice"), 
        health: 100 
    };
    
    println!("{}", player.status());
}
```

---

## The Orphan Rule

There's a restriction: you can only implement a trait if either:

- You defined the trait, OR
- You defined the type

This prevents conflicts when two crates try to implement the same trait for the same type.

```rust
// This would NOT compile if written in your crate:
// impl Display for Vec<i32> { ... }
// ERROR: neither Display nor Vec are defined in this crate

// But you CAN implement your trait for foreign types:
trait Describable {
    fn describe(&self) -> String;
}

impl Describable for i32 {
    fn describe(&self) -> String {
        format!("The number {}", self)
    }
}

// And you CAN implement foreign traits for your types:
struct Player { name: String }

impl std::fmt::Display for Player {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Player: {}", self.name)
    }
}

fn main() {
    println!("{}", 42.describe());
    println!("{}", Player { name: String::from("Alice") });
}
```

If you need to implement a foreign trait for a foreign type (which the orphan rule prevents), you can use a **newtype** to create a "wrapper" type that you own. This acts as an adapter, allowing you to bridge the gap. For more on newtypes, see the [Newtypes chapter](../dop_fundamentals/05-newtypes.md) in the DOP Fundamentals section.

---

## Real-World Example: Debug and Clone

The standard library's derive macros use conditional implementation:

```rust
// When you write:
#[derive(Debug, Clone)]
struct Container<T> {
    value: T,
}

// The compiler generates something like:
// impl<T: Debug> Debug for Container<T> { ... }
// impl<T: Clone> Clone for Container<T> { ... }

fn main() {
    let c1 = Container { value: 42 };
    println!("{:?}", c1);  // Works: i32 is Debug
    
    let c2 = c1.clone();   // Works: i32 is Clone
    println!("{:?}", c2);
}
```

The derived implementations are conditional on `T` having those same capabilities.

---

## The Mental Model

**C# thinking**: "I explicitly implement interfaces on my classes. What I implement is fixed at definition time."

**Rust thinking**: "Implementations can be conditional. Capabilities emerge from the combination of types and their properties. I can add behavior to types based on what they can already do."

This is composition at the type level. Small traits combine to provide rich functionality, and the compiler figures out what's available for each concrete type.
