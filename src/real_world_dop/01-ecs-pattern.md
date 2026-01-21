# Entity-Component-System Pattern

Data-Oriented Programming isn't just "how Rust works" - it's a design philosophy that powers high-performance systems. The Entity-Component-System (ECS) pattern from game development is a pure expression of DOP. [Bevy](https://bevy.org), a popular Rust game engine, uses ECS as its core architecture. While this isn't a game design book, understanding ECS reveals how DOP principles apply in real-world scenarios beyond games.

---

## The OOP Instinct: Inheritance Hierarchies

In C#, you might model game entities with inheritance:

```csharp
// C# approach: inheritance hierarchy
abstract class Entity { 
    public Vector2 Position { get; set; }
}

class Player : Entity { 
    public int Health { get; set; }
}

class Enemy : Entity, IDamageable { 
    public int Health { get; set; }
    public AI Brain { get; set; }
}
```

This creates problems: What if an Enemy needs to share behavior with Player? What about a destructible Projectile that has Health?

---

## The DOP Alternative: Composition Over Inheritance

In DOP, we separate "what things are" from "what things have". Entities are just IDs, and data lives in separate component storage:

```rust,noplayground
use std::collections::HashMap;

// Components are just data - no behavior, no hierarchy
#[derive(Clone, Copy)]
struct Position { x: f32, y: f32 }

#[derive(Clone, Copy)]
struct Velocity { dx: f32, dy: f32 }

#[derive(Clone, Copy)]
struct Health { current: i32, max: i32 }

// An entity is just an identifier
#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Entity(u32);

// Components stored separately, indexed by entity
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
```

Entities gain capabilities by having components added - no inheritance needed.

Games have large quantities of entities, with lots of varied components, which is why they use this "columnar" storage format (storing components in separate collections indexed by entity ID). This allows systems to work by iterating over these large arrays of data efficiently. They don't have to use locking to protect unrelated data, and they can use the CPU cache extremely efficiently because they are usually working with large contiguous arrays of data.

---

## Systems: Functions Over Data

Behavior lives in *systems* - functions that operate on entities with specific components. In [Bevy](https://bevy.org), you declare what data your system needs via query parameters, and the framework fills them in automatically:

```rust,ignore
use bevy::prelude::*;

// Components are simple structs marked with #[derive(Component)]
#[derive(Component)]
struct Position { x: f32, y: f32 }

#[derive(Component)]
struct Velocity { dx: f32, dy: f32 }

#[derive(Component)]
struct Health { current: i32, max: i32 }

// Movement system: Query tells Bevy "give me all entities with Position AND Velocity"
// Bevy automatically finds matching entities and calls this function
fn movement_system(mut query: Query<(&mut Position, &Velocity)>, time: Res<Time>) {
    for (mut pos, vel) in &mut query {
        pos.x += vel.dx * time.delta_secs();
        pos.y += vel.dy * time.delta_secs();
    }
}

// Health regen: only needs entities with Health component
fn health_regen_system(mut query: Query<&mut Health>) {
    for mut health in &mut query {
        if health.current < health.max {
            health.current += 1;
        }
    }
}

// Startup system: runs once to spawn initial entities
// Commands lets us create/destroy entities and add/remove components
fn setup(mut commands: Commands) {
    // Player: has position, velocity, and health - will move and regenerate
    commands.spawn((
        Position { x: 0.0, y: 0.0 },
        Velocity { dx: 10.0, dy: 5.0 },
        Health { current: 80, max: 100 },
    ));
    
    // Enemy: has position, velocity, and health
    commands.spawn((
        Position { x: 100.0, y: 50.0 },
        Velocity { dx: -5.0, dy: 0.0 },
        Health { current: 50, max: 50 },
    ));
    
    // Tree: only has position - won't move, can't be damaged
    commands.spawn(Position { x: 50.0, y: 50.0 });
}

// The function signature IS the query - no manual filtering needed
// Bevy inspects the function parameters and wires everything up
fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_systems(Update, (movement_system, health_regen_system))
        .run();
}
```

The tree (with only `Position`) won't be matched by `movement_system`'s query because it requires *both* `Position` and `Velocity`. Also, the health system and the movement system can run in parallel because they touch completely distinct data. **The type system defines data access clearly and safely.**

---

## Why This Pattern Matters

ECS demonstrates core DOP principles:

1. **Data and behavior are separate** - Components are pure data, systems are pure functions
2. **Composition over inheritance** - Capabilities come from having components, not from class hierarchies  
3. **Clear data flow** - Systems declare exactly what they read and write
4. **Parallelism-ready** - Systems touching different components can run in parallel

Game engines like Bevy use ECS, but the pattern applies anywhere you have entities with varying capabilities - and as we'll see, similar thinking applies to request pipelines.
