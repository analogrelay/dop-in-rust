# Generics and Trait Bounds

Traits become powerful when combined with generics. Instead of writing code for specific types, you write code for "any type that has this capability."

---

## A Function That Works on Any Damageable

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
    fn is_alive(&self) -> bool { self.health() > 0 }
}

struct Player { health: i32 }
struct Crate { health: i32 }

impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) { self.health -= amount; }
    fn health(&self) -> i32 { self.health }
}

impl Damageable for Crate {
    fn take_damage(&mut self, amount: i32) { self.health -= amount; }
    fn health(&self) -> i32 { self.health }
}

// Generic function: works on ANY type that implements Damageable
fn apply_explosion<T: Damageable>(target: &mut T, damage: i32) {
    println!("Explosion deals {} damage!", damage);
    target.take_damage(damage);
    if !target.is_alive() {
        println!("Target destroyed!");
    }
}

fn main() {
    let mut player = Player { health: 100 };
    let mut crate1 = Crate { health: 30 };
    
    apply_explosion(&mut player, 25);
    println!("Player health: {}\n", player.health());
    
    apply_explosion(&mut crate1, 50);
    println!("Crate health: {}", crate1.health());
}
```

The `<T: Damageable>` is a **trait bound** - it says "T can be any type, as long as it implements Damageable."

---

## Monomorphization: Zero-Cost Abstraction

When you call `apply_explosion(&mut player, 25)`, the compiler generates:

```rust
// Compiler generates this specialized version for Player
fn apply_explosion_player(target: &mut Player, damage: i32) {
    println!("Explosion deals {} damage!", damage);
    target.take_damage(damage);  // Direct call to Player::take_damage
    if !target.is_alive() {
        println!("Target destroyed!");
    }
}
```

And for `apply_explosion(&mut crate1, 50)`, it generates a separate version for Crate.

This is **monomorphization**: the generic function becomes multiple specialized functions at compile time. No runtime overhead!

In more formal terms, monomorphization is the transformation of a **polymorphic** type or function (one that works with many types) into several **monomorphic** variants (each specialized for a single concrete type). The polymorphic generic code you write gets "instantiated" into monomorphic code for each type you actually use it with.

---

## Multiple Trait Bounds

Sometimes you need a type with multiple capabilities:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
}

trait Named {
    fn name(&self) -> &str;
}

struct Player {
    name: String,
    health: i32,
}

impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) { self.health -= amount; }
    fn health(&self) -> i32 { self.health }
}

impl Named for Player {
    fn name(&self) -> &str { &self.name }
}

// T must implement BOTH Damageable AND Named
fn damage_with_message<T: Damageable + Named>(target: &mut T, amount: i32) {
    println!("{} takes {} damage!", target.name(), amount);
    target.take_damage(amount);
    println!("{} now has {} health", target.name(), target.health());
}

fn main() {
    let mut player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    damage_with_message(&mut player, 30);
}
```

The `+` combines multiple bounds: the type must have ALL the capabilities.

When trait bounds get complicated, you can also use a [`where` clause](https://doc.rust-lang.org/book/ch10-02-traits.html#clearer-trait-bounds-with-where-clauses) for clarity.

---

## Rust Generics vs C# Generics

In C#, generics use **reification** - type information exists at runtime:

```csharp
void Process<T>(T item) {
    // Can check typeof(T) at runtime
    // Single version of the code handles all types
}
```

In Rust, generics use **monomorphization** - specialized code is generated:

```rust
fn process<T>(item: T) {
    // No runtime type info
    // Compiler generates separate code for each T
}
```

| Aspect | C# Generics | Rust Generics |
|--------|-------------|---------------|
| When resolved | Runtime | Compile time |
| Code generated | One version | One per type |
| Performance | Virtual dispatch possible | Direct calls, inlineable |
| Binary size | Smaller | Larger |
| Compile time | Faster | Slower |

---

## impl Trait: Simpler Syntax

For simple cases, `impl Trait` is a shorthand:

```rust
use std::fmt::Display;

// These two are equivalent:
fn print_thing<T: Display>(thing: T) {
    println!("{}", thing);
}

fn print_thing_simpler(thing: impl Display) {
    println!("{}", thing);
}

fn main() {
    print_thing("hello");
    print_thing_simpler(42);
}
```

`impl Trait` in argument position means "some type that implements this trait." It's syntactic sugar for simple bounds.

---

## The Power of Compile-Time Polymorphism

Because generics are resolved at compile time:

1. **No runtime cost** - Calls are direct, can be inlined
2. **Type errors caught early** - Can't pass wrong type
3. **Optimizations apply** - Compiler sees the concrete types

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
}

struct Player { health: i32 }
impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) { self.health -= amount; }
}

fn damage_many<T: Damageable>(targets: &mut [T], amount: i32) {
    for target in targets {
        target.take_damage(amount);  // Direct call, inlined
    }
}

fn main() {
    let mut players = vec![
        Player { health: 100 },
        Player { health: 100 },
        Player { health: 100 },
    ];
    
    damage_many(&mut players, 10);
    
    for (i, p) in players.iter().enumerate() {
        println!("Player {}: {} health", i, p.health);
    }
}
```

The loop compiles to direct `Player::take_damage` calls - as fast as if you wrote it by hand.
