# Systems: Functions Over Data

In ECS, behavior lives in *systems* - functions that operate on entities with specific components.

---

## Systems are Just Functions

A system queries for entities with certain components, then processes them:

```rust
use std::collections::HashMap;

struct Position { x: f32, y: f32 }
struct Velocity { dx: f32, dy: f32 }
struct Health { current: i32, max: i32 }

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Entity(u32);

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

The movement system operates on anything with Position AND Velocity:

```rust
// Systems are just functions that operate on component data
fn movement_system(world: &mut World, delta_time: f32) {
    // Find all entities that have BOTH position and velocity
    let entities_to_move: Vec<Entity> = world.velocities
        .keys()
        .filter(|e| world.positions.contains_key(e))
        .copied()
        .collect();
    
    for entity in entities_to_move {
        if let (Some(pos), Some(vel)) = (
            world.positions.get_mut(&entity),
            world.velocities.get(&entity)
        ) {
            pos.x += vel.dx * delta_time;
            pos.y += vel.dy * delta_time;
        }
    }
}

fn main() {
    let mut world = World::new();
    
    // Entity with both position and velocity - WILL move
    let player = world.spawn();
    world.positions.insert(player, Position { x: 0.0, y: 0.0 });
    world.velocities.insert(player, Velocity { dx: 10.0, dy: 5.0 });
    
    // Entity with only position - will NOT be affected by movement system
    let tree = world.spawn();
    world.positions.insert(tree, Position { x: 50.0, y: 50.0 });
    
    println!("Before: Player at ({}, {})", 
             world.positions[&player].x, world.positions[&player].y);
    println!("Before: Tree at ({}, {})", 
             world.positions[&tree].x, world.positions[&tree].y);
    
    // Run one "frame" - 1 second of game time
    movement_system(&mut world, 1.0);
    
    println!("After: Player at ({}, {})", 
             world.positions[&player].x, world.positions[&player].y);
    println!("After: Tree at ({}, {})", 
             world.positions[&tree].x, world.positions[&tree].y);
}
```

The tree doesn't move - it has no Velocity component. Behavior emerges from data!

---

## Multiple Systems, Clear Responsibilities

Each system handles one concern:

```rust
use std::collections::HashMap;

struct Position { x: f32, y: f32 }
struct Velocity { dx: f32, dy: f32 }
struct Health { current: i32, max: i32 }

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Entity(u32);

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

fn movement_system(world: &mut World, delta_time: f32) {
    let moving: Vec<Entity> = world.velocities.keys()
        .filter(|e| world.positions.contains_key(e))
        .copied()
        .collect();
        
    for entity in moving {
        if let (Some(pos), Some(vel)) = (
            world.positions.get_mut(&entity),
            world.velocities.get(&entity)
        ) {
            pos.x += vel.dx * delta_time;
            pos.y += vel.dy * delta_time;
        }
    }
}

fn health_regen_system(world: &mut World) {
    // All entities with health regenerate 1 HP per tick
    for health in world.healths.values_mut() {
        if health.current < health.max {
            health.current = (health.current + 1).min(health.max);
        }
    }
}

fn death_system(world: &mut World) -> Vec<Entity> {
    // Find and remove entities with zero health
    let dead: Vec<Entity> = world.healths
        .iter()
        .filter(|(_, h)| h.current <= 0)
        .map(|(e, _)| *e)
        .collect();
    
    for entity in &dead {
        world.positions.remove(entity);
        world.velocities.remove(entity);
        world.healths.remove(entity);
    }
    
    dead
}

fn main() {
    let mut world = World::new();
    
    let player = world.spawn();
    world.positions.insert(player, Position { x: 0.0, y: 0.0 });
    world.velocities.insert(player, Velocity { dx: 1.0, dy: 0.0 });
    world.healths.insert(player, Health { current: 50, max: 100 });
    
    let enemy = world.spawn();
    world.positions.insert(enemy, Position { x: 100.0, y: 0.0 });
    world.healths.insert(enemy, Health { current: 0, max: 50 });  // Already dead!
    
    // Game loop
    println!("=== Frame 1 ===");
    movement_system(&mut world, 0.016);
    health_regen_system(&mut world);
    let dead = death_system(&mut world);
    
    if !dead.is_empty() {
        println!("Entities died: {:?}", dead.iter().map(|e| e.0).collect::<Vec<_>>());
    }
    
    println!("Player health: {}/{}", 
             world.healths[&player].current, 
             world.healths[&player].max);
}
```

Systems are composable, testable, and independent. This is DOP in action!

