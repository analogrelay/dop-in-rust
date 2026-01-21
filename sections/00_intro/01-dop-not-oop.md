# DOP not OOP

You know **Object-Oriented Programming (OOP)** - it's the paradigm behind C#, Java, and most mainstream languages.

**Data-Oriented Programming (DOP)** is a different way of thinking. It's not new - game developers and systems programmers have used it for decades - but Rust makes it the default.

---

## The Core Idea

**In OOP**: Objects encapsulate data and behavior together

```csharp
public class Player {
    private int health;
    private string name;

    public Player(string name) {
        this.name = name;
        this.health = 100;
    }

    public void TakeDamage(int amount) {
        health -= amount;
    }
}
```

**In DOP**: Data describes *what things are*. Behavior describes *what things do*.

```rust
// Data: what a Player IS
struct Player {
    health: i32,
    name: String,
}
```

The struct just defines the shape of the data - nothing more. No constructors run, no base classes initialize.

```rust
// Behavior: what a Player DOES
impl Player {
    fn new(name: String) -> Player {
        Player { health: 100, name }
    }

    fn take_damage(&mut self, amount: i32) {
        self.health -= amount;
    }
}
```

The `impl` block adds behavior separately. Notice how `&mut self` makes mutation explicit.

```rust
fn main() {
    let mut player = Player::new(String::from("Alice"));
    println!("Starting health: {}", player.health);
    
    player.take_damage(25);
    println!("After damage: {}", player.health);
}
```

---

## Why This Matters

This separation is **intentional**. It enables:

- **Composability**: Behavior can be added to types after the fact. Data can be combined with other data without worrying about how behaviors conflict.
- **Testability**: Data is transparent and inspectable
- **Performance**: Data layout can be optimized independently of behavior

Rust's "restrictions" (ownership, borrowing, lifetimes) are **natural consequences** of thinking about data first.

> By the end of this talk, you'll understand why this separation leads to better code.
