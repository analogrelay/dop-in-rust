# Enums: Algebraic Data Types

Rust enums are more powerful than C# enums. Each variant can hold different data.

This is called an "algebraic data type" - something C# doesn't have natively.

```rust
enum GameEvent {
    PlayerJoined { name: String },
    PlayerMoved { x: f32, y: f32 },
    DamageTaken { amount: i32, source: String },
    PlayerDied,
}
```

Each variant is a distinct shape. `PlayerJoined` carries a name. `PlayerMoved` carries coordinates. `PlayerDied` carries nothing.

---

## Pattern Matching

Pattern matching destructures the data - no casting, no type checking at runtime:

```rust
fn main() {
    let event = GameEvent::DamageTaken {
        amount: 25,
        source: String::from("Goblin"),
    };

    match event {
        GameEvent::PlayerJoined { name } => {
            println!("{} joined the game", name);
        }
        GameEvent::PlayerMoved { x, y } => {
            println!("Player moved to ({}, {})", x, y);
        }
        GameEvent::DamageTaken { amount, source } => {
            println!("Took {} damage from {}", amount, source);
        }
        GameEvent::PlayerDied => {
            println!("Player died!");
        }
    }
}
```

The compiler ensures you handle **all** variants. Try commenting out a match arm - the compiler will tell you what you missed.

This is exhaustive matching - a safety net that C# `switch` statements don't provide.
