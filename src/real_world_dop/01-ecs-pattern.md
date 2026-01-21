# Real-World DOP: Entity-Component-System

Data-Oriented Programming isn't just "how Rust works" - it's a design philosophy that powers high-performance systems. Let's see how it manifests in real codebases.

---

## The OOP Instinct: Inheritance Hierarchies

In C#, you might model game entities like this:

```csharp
// C# approach: inheritance hierarchy
abstract class Entity { 
    public Vector2 Position { get; set; }
}

class Player : Entity { 
    public int Health { get; set; }
    public void Move(Vector2 delta) { ... }
}

class Enemy : Entity, IDamageable { 
    public int Health { get; set; }
    public AI Brain { get; set; }
}

class Projectile : Entity { 
    public int Damage { get; set; }
    public Vector2 Velocity { get; set; }
}
```

This creates problems: What if something is both a Player AND has AI? What about a Projectile that has Health (destructible)?

---

## The DOP Alternative: Components as Data

In DOP, we separate "what things are" from "what things have":

```rust
// Components are just data - no behavior, no hierarchy
struct Position { x: f32, y: f32 }
struct Velocity { dx: f32, dy: f32 }
struct Health { current: i32, max: i32 }
struct Damage { amount: i32 }
struct AIBrain { state: AIState }

#[derive(Clone, Copy)]
enum AIState {
    Idle,
    Chasing,
    Attacking,
}
```

Entities are just IDs. They don't "contain" data - they're keys into component storage:

```rust
// An entity is just an identifier
#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Entity(u32);
```

---

## Storing Components Separately

Components live in their own storage, indexed by entity:

```rust
use std::collections::HashMap;

struct Position { x: f32, y: f32 }
struct Velocity { dx: f32, dy: f32 }
struct Health { current: i32, max: i32 }

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Entity(u32);

// Each component type has its own storage
struct World {
    next_entity: u32,
    positions: HashMap<Entity, Position>,
    velocities: HashMap<Entity, Velocity>,
    healths: HashMap<Entity, Health>,
}

impl World {
    fn new() -> Self {
        World {
            next_entity: 0,
            positions: HashMap::new(),
            velocities: HashMap::new(),
            healths: HashMap::new(),
        }
    }
    
    fn spawn(&mut self) -> Entity {
        let entity = Entity(self.next_entity);
        self.next_entity += 1;
        entity
    }
}

fn main() {
    let mut world = World::new();
    
    // Create a player: has position, velocity, and health
    let player = world.spawn();
    world.positions.insert(player, Position { x: 0.0, y: 0.0 });
    world.velocities.insert(player, Velocity { dx: 0.0, dy: 0.0 });
    world.healths.insert(player, Health { current: 100, max: 100 });
    
    // Create a projectile: has position and velocity, but no health
    let projectile = world.spawn();
    world.positions.insert(projectile, Position { x: 10.0, y: 5.0 });
    world.velocities.insert(projectile, Velocity { dx: -1.0, dy: 0.0 });
    // No health component - projectiles can't be damaged
    
    println!("Player at ({}, {})", 
             world.positions[&player].x, 
             world.positions[&player].y);
    println!("Projectile at ({}, {})", 
             world.positions[&projectile].x, 
             world.positions[&projectile].y);
}
```

Entities gain capabilities by having components added - no inheritance needed!

