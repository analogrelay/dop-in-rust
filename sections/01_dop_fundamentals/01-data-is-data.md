# Data Structures are Just Data

In Rust, structs and enums describe data layout directly - no constructors, no hidden state, no inheritance.

---

## Structs: Named Fields

A struct is just named fields. No constructor runs, no base class is initialized.

```rust
struct Player {
    name: String,
    health: i32,
    position: (f32, f32),
}
```

Creating one is straightforward - just fill in the fields:

```rust
fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
        position: (0.0, 0.0),
    };

    // Fields are directly accessible (within the same module)
    println!("{} has {} health at position {:?}", 
             player.name, player.health, player.position);
}
```

No `new` keyword required. The data is transparent - you can see exactly what's there.
