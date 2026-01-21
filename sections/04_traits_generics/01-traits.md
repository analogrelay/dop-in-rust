# Traits as Shared Behavior

We've seen how Rust separates data (structs) from behavior (impl blocks). But what if multiple types need the same behavior? That's where traits come in.

---

## Defining a Trait

A trait defines a set of methods that types can implement:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
    
    fn is_alive(&self) -> bool {
        self.health() > 0  // Default implementation
    }
}
```

This says: "Any type that is `Damageable` must provide `take_damage` and `health`, and gets `is_alive` for free."

---

## Implementing a Trait

Types opt into traits explicitly:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
    
    fn is_alive(&self) -> bool {
        self.health() > 0
    }
}

struct Player {
    name: String,
    health: i32,
    armor: i32,
}

impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) {
        // Players have armor that reduces damage
        let actual_damage = (amount - self.armor).max(0);
        self.health -= actual_damage;
    }
    
    fn health(&self) -> i32 {
        self.health
    }
}

fn main() {
    let mut player = Player {
        name: String::from("Alice"),
        health: 100,
        armor: 5,
    };
    
    player.take_damage(20);
    println!("{} has {} health, alive: {}", 
             player.name, player.health(), player.is_alive());
}
```

---

## Multiple Types, Same Trait

Different types can implement the same trait differently:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
    
    fn is_alive(&self) -> bool {
        self.health() > 0
    }
}

struct Player {
    name: String,
    health: i32,
    armor: i32,
}

impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) {
        let actual_damage = (amount - self.armor).max(0);
        self.health -= actual_damage;
    }
    
    fn health(&self) -> i32 {
        self.health
    }
}

struct Crate {
    health: i32,
}

impl Damageable for Crate {
    fn take_damage(&mut self, amount: i32) {
        // Crates have no armor, take full damage
        self.health -= amount;
    }
    
    fn health(&self) -> i32 {
        self.health
    }
}

fn main() {
    let mut player = Player { 
        name: String::from("Alice"), 
        health: 100, 
        armor: 5 
    };
    let mut crate1 = Crate { health: 50 };
    
    player.take_damage(20);  // Takes 15 (armor absorbs 5)
    crate1.take_damage(20);  // Takes full 20
    
    println!("Player: {}, Crate: {}", player.health(), crate1.health());
}
```

---

## Overriding Default Implementations

Types can override default methods when needed:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
    
    fn is_alive(&self) -> bool {
        self.health() > 0
    }
}

struct Zombie {
    health: i32,
}

impl Damageable for Zombie {
    fn take_damage(&mut self, amount: i32) {
        self.health -= amount;
    }
    
    fn health(&self) -> i32 {
        self.health
    }
    
    // Zombies are "alive" even at 0 health - they need to be destroyed!
    fn is_alive(&self) -> bool {
        self.health() > -10
    }
}

fn main() {
    let mut zombie = Zombie { health: 20 };
    
    zombie.take_damage(25);
    println!("Health: {}, Alive: {}", zombie.health(), zombie.is_alive());
    
    zombie.take_damage(10);
    println!("Health: {}, Alive: {}", zombie.health(), zombie.is_alive());
}
```

---

## Traits vs C# Interfaces

| C# Interface | Rust Trait |
|-------------|-----------|
| Methods only (until C# 8) | Methods, constants, types |
| Default implementations (C# 8+) | Default implementations (always) |
| Implicit implementation | Explicit `impl Trait for Type` |
| Runtime dispatch by default | Compile-time dispatch by default |
| Part of type identity | Capability that can be added |

The key difference: In C#, you implement interfaces when you define the class. In Rust, you can implement traits for any type, anywhere (with some restrictions).

---

## Multiple Traits, One Type

Types can implement as many traits as needed:

```rust
trait Damageable {
    fn take_damage(&mut self, amount: i32);
    fn health(&self) -> i32;
}

trait Moveable {
    fn move_by(&mut self, dx: f32, dy: f32);
    fn position(&self) -> (f32, f32);
}

struct Player {
    health: i32,
    x: f32,
    y: f32,
}

impl Damageable for Player {
    fn take_damage(&mut self, amount: i32) { self.health -= amount; }
    fn health(&self) -> i32 { self.health }
}

impl Moveable for Player {
    fn move_by(&mut self, dx: f32, dy: f32) {
        self.x += dx;
        self.y += dy;
    }
    fn position(&self) -> (f32, f32) { (self.x, self.y) }
}

fn main() {
    let mut player = Player { health: 100, x: 0.0, y: 0.0 };
    
    player.move_by(5.0, 3.0);
    player.take_damage(10);
    
    println!("Position: {:?}, Health: {}", player.position(), player.health());
}
```

No inheritance hierarchy needed. Capabilities compose freely.

---

## The Mental Model

**C# thinking**: "This class IS-A something. It inherits from a base class and implements interfaces that define what it is."

**Rust thinking**: "This type HAS capabilities. It can do these things because it implements these traits. Capabilities are independent."

Traits describe what a type can DO, not what it IS. This is composition over inheritance, built into the language.
