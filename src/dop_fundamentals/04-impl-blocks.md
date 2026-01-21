# Behavior Lives in Impl Blocks

Behavior is separate from data - it lives in `impl` blocks. You can have multiple `impl` blocks for the same type, organized however makes sense.

```rust,noplayground
struct Player {
    name: String,
    health: i32,
    max_health: i32,
}
```

---

## Associated Functions

Associated functions don't take `self` - they're like static methods in C#. By convention, `new` is the constructor name:

```rust,noplayground
impl Player {
    fn new(name: String) -> Player {
        Player {
            name,
            health: 100,
            max_health: 100,
        }
    }
}
```

In C#, static methods are often used because there are no free functions - everything must belong to a class. This leads to "static utility classes" that are really just namespaces for functions:

```csharp
// C# - static class as a container for functions
public static class MathUtils {
    public static double Lerp(double a, double b, double t) { ... }
    public static double Clamp(double value, double min, double max) { ... }
}
```

In Rust, the equivalent of a C# `static class` is simply a **module** (`mod`) with free functions and constants. Types should be containers for data (and highly related behavior), not just containers for behavior:

```rust,noplayground
// Rust - module with free functions
mod math_utils {
    pub fn lerp(a: f64, b: f64, t: f64) -> f64 {
        a + (b - a) * t
    }
    
    pub fn clamp(value: f64, min: f64, max: f64) -> f64 {
        if value < min { min } else if value > max { max } else { value }
    }
}
```

Use associated functions on types when the function is **conceptually tied to the type itself** (like constructors, or type-specific utilities). Use free functions in modules when the behavior is more general-purpose or doesn't conceptually "belong" to a single type.

---

## The Self Parameter

The `self` parameter is explicit - there's no hidden `this`. This tells you exactly how data flows:

```rust,noplayground
impl Player {
    // &self = borrows immutably (read-only access)
    fn is_alive(&self) -> bool {
        self.health > 0
    }
```

In C#, methods are an inherent part of a class - `this` is magical and implicit. In Rust, methods are really just **syntax sugar for bare functions** that happen to take `Self` as their first parameter:

```rust,noplayground
impl Player {
    // This method...
    fn is_alive(&self) -> bool {
        self.health > 0
    }
}

// ...is essentially equivalent to this free function:
fn is_alive(player: &Player) -> bool {
    player.health > 0
}
```

The only difference is namespacing and call syntax. Both work:

```rust
# struct Player {
#     name: String,
#     health: i32,
#     max_health: i32,
# }
#
# impl Player {
#     fn new(name: String) -> Player {
#         Player { name, health: 100, max_health: 100 }
#     }
# }
#
impl Player {
    fn take_damage(&mut self, amount: i32) {
        self.health = (self.health - amount).max(0);
    }
}

fn main() {
    let mut player = Player::new(String::from("Alice"));
    
    // Method syntax - what you'll usually write
    player.take_damage(10);
    
    // But this is exactly equivalent - calling it as a function!
    Player::take_damage(&mut player, 20);
    
    println!("{} has {} health", player.name, player.health);
}
```

This isn't just an implementation detail - it reinforces that **behavior is attached to data, not embedded in it**. The `impl` block is organizational, not fundamental.

---

## Self Variants

The three forms of `self` control ownership, just like any other parameter:

```rust,noplayground
impl Player {
    // &self = borrows immutably (read-only access)
    fn is_alive(&self) -> bool {
        self.health > 0
    }

    fn health_percentage(&self) -> f32 {
        self.health as f32 / self.max_health as f32 * 100.0
    }

    // &mut self = borrows mutably (read-write access)
    fn heal(&mut self, amount: i32) {
        self.health = (self.health + amount).min(self.max_health);
        println!("{} heals {} HP! Health: {}", self.name, amount, self.health);
    }

    // self (no &) = takes ownership, consuming the value
    // after this call, self is destroyed and can't be used again
    fn into_name(self) -> String {
        self.name
    }
}
```

In Rust, there are conventional method name prefixes used to indicate some of these ownership semantics:

| Prefix | Parameter | Meaning |
|--------|-----------| -----------------------|
| into_  | self | consumes and transforms |
| as_    | &self | converts a reference to ourself into another type |
| to_    | &self | creates an owned copy of ourself as a different type |

This **does not** mean that all methods with this kind of self parameter use this prefix, but it's a common pattern used for transformative methods.

This even goes beyond just ownership and standard borrows. You can have self parameters use other smart pointers too, to enforce certain usage patterns:

```rust
use std::sync::Arc;

pub struct Cache {
    val: usize
}

impl Cache {
    pub fn read(self: Arc<Self>) -> usize { self.val }
}

pub fn main() {
    let cache = Arc::new(Cache { val: 42 });
    println!("Value: {:?}", cache.read());
}
```

The main function would fail to compile if we were to call `cache.read()` without wrapping `self` in `Arc`:

```rust
# use std::sync::Arc;
# pub struct Cache {
#     val: usize
# }
# impl Cache {
#     pub fn read(self: Arc<Self>) -> usize { self.val }
# }
pub fn main() {
    let cache = Cache { val: 42 };
    println!("Value: {:?}", cache.read());
}
```

**Use this with care** - You're enforcing a specific ownership model on users of your type. Only do this when it's really necessary for safety or correctness.

---

## Using Methods

```rust
# struct Player {
#     name: String,
#     health: i32,
#     max_health: i32,
# }
#
# impl Player {
#     fn new(name: String) -> Player {
#         Player { name, health: 100, max_health: 100 }
#     }
#     fn is_alive(&self) -> bool { self.health > 0 }
#     fn health_percentage(&self) -> f32 {
#         self.health as f32 / self.max_health as f32 * 100.0
#     }
#     fn take_damage(&mut self, amount: i32) {
#         self.health = (self.health - amount).max(0);
#     }
#     fn heal(&mut self, amount: i32) {
#         self.health = (self.health + amount).min(self.max_health);
#         println!("{} heals {} HP! Health: {}", self.name, amount, self.health);
#     }
#     fn into_name(self) -> String { self.name }
# }
#
fn main() {
    // Call associated function with :: syntax
    let mut player = Player::new(String::from("Alice"));

    // &self methods - can call multiple times, player is just borrowed
    println!("{} at {}% health", player.name, player.health_percentage());
    println!("Alive? {}", player.is_alive());

    // &mut self method - needs `mut` binding to call
    player.heal(10);

    // You can also call methods as functions - it's the same thing!
    Player::take_damage(&mut player, 30);

    // self method - consumes the player
    let name = player.into_name();
    println!("Player's name was: {}", name);

    // Uncommenting this would fail - player was consumed:
    // println!("{}", player.health);
    // ERROR: borrow of moved value: `player`
}
```

Function signatures tell you **everything** about how data flows.
