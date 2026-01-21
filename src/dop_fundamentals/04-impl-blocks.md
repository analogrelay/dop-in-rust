# Behavior Lives in Impl Blocks

Behavior is separate from data - it lives in `impl` blocks. You can have multiple `impl` blocks for the same type, organized however makes sense.

```rust
struct Player {
    name: String,
    health: i32,
    max_health: i32,
}
```

---

## Associated Functions

Associated functions don't take `self` - they're like static methods in C#. By convention, `new` is the constructor name:

```rust
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

---

## The Self Parameter

The `self` parameter is explicit - there's no hidden `this`. This tells you exactly how data flows:

```rust
impl Player {
    // &self = borrows immutably (read-only access)
    fn is_alive(&self) -> bool {
        self.health > 0
    }

    fn health_percentage(&self) -> f32 {
        self.health as f32 / self.max_health as f32 * 100.0
    }

    // &mut self = borrows mutably (read-write access)
    fn take_damage(&mut self, amount: i32) {
        self.health = (self.health - amount).max(0);
        println!("{} takes {} damage! Health: {}", self.name, amount, self.health);
    }

    fn heal(&mut self, amount: i32) {
        self.health = (self.health + amount).min(self.max_health);
        println!("{} heals {} HP! Health: {}", self.name, amount, self.health);
    }

    // self (no &) = takes ownership, consuming the value
    fn into_name(self) -> String {
        self.name
    }
}
```

---

## Using Methods

```rust
fn main() {
    // Call associated function with :: syntax
    let mut player = Player::new(String::from("Alice"));

    // &self methods - can call multiple times, player is just borrowed
    println!("{} at {}% health", player.name, player.health_percentage());
    println!("Alive? {}", player.is_alive());

    // &mut self methods - need `mut` binding to call these
    player.take_damage(30);
    player.heal(10);

    // self method - consumes the player
    let name = player.into_name();
    println!("Player's name was: {}", name);

    // Uncommenting this would fail - player was consumed:
    // println!("{}", player.health);
    // ERROR: borrow of moved value: `player`
}
```

Function signatures tell you **everything** about how data flows.
