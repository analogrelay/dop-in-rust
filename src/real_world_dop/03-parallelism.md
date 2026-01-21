# Parallelism: DOP's Hidden Superpower

When data and behavior are separate, and ownership is explicit, parallelism becomes safe and straightforward.

---

## The OOP Parallelism Problem

In OOP, objects own their data and can mutate it at any time. This makes parallelism dangerous:

```text
Thread 1: player.TakeDamage(10)  →  reads health, writes health
Thread 2: player.Heal(5)         →  reads health, writes health

Race condition! Which write wins? Is health consistent?
```

C# "solves" this with locks, but locks are error-prone and hurt performance.

---

## DOP Makes Parallelism Natural

When systems operate on *different component types*, they can run in parallel without locks:

```rust
use std::thread;

// Components
#[derive(Clone, Copy)]
struct Position { x: f32, y: f32 }

#[derive(Clone, Copy)]
struct Velocity { dx: f32, dy: f32 }

#[derive(Clone, Copy)]
struct Health { current: i32, max: i32 }

fn main() {
    // Separate data for each system
    let mut positions = vec![
        Position { x: 0.0, y: 0.0 },
        Position { x: 10.0, y: 5.0 },
        Position { x: -5.0, y: 3.0 },
    ];
    
    let velocities = vec![
        Velocity { dx: 1.0, dy: 0.0 },
        Velocity { dx: 0.0, dy: -1.0 },
        Velocity { dx: 0.5, dy: 0.5 },
    ];
    
    let mut healths = vec![
        Health { current: 80, max: 100 },
        Health { current: 50, max: 100 },
        Health { current: 100, max: 100 },
    ];
    
    // These two operations touch DIFFERENT data - safe to parallelize!
    // Movement system: reads velocities, writes positions
    // Health regen: reads/writes healths
    
    // Using scoped threads to demonstrate the concept
    thread::scope(|s| {
        // Movement system - owns positions mutably, borrows velocities
        s.spawn(|| {
            for (pos, vel) in positions.iter_mut().zip(velocities.iter()) {
                pos.x += vel.dx;
                pos.y += vel.dy;
            }
            println!("Movement complete!");
        });
        
        // Health regen - owns healths mutably (no overlap!)
        s.spawn(|| {
            for health in healths.iter_mut() {
                if health.current < health.max {
                    health.current += 1;
                }
            }
            println!("Health regen complete!");
        });
    });
    
    println!("\nAfter parallel update:");
    for (i, (pos, health)) in positions.iter().zip(healths.iter()).enumerate() {
        println!("Entity {}: pos=({:.1}, {:.1}), health={}/{}", 
                 i, pos.x, pos.y, health.current, health.max);
    }
}
```

The borrow checker *guarantees* these threads don't conflict!

---

## Data Parallelism with Rayon

For data-parallel operations, the rayon crate makes it trivial:

```rust
// Note: This example shows the pattern. In the presentation,
// you'd need to add rayon to Cargo.toml to actually run it.

#[derive(Clone, Copy)]
struct Position { x: f32, y: f32 }

#[derive(Clone, Copy)]  
struct Velocity { dx: f32, dy: f32 }

fn main() {
    let mut positions: Vec<Position> = (0..10000)
        .map(|i| Position { x: i as f32, y: 0.0 })
        .collect();
    
    let velocities: Vec<Velocity> = (0..10000)
        .map(|_| Velocity { dx: 1.0, dy: 0.5 })
        .collect();
    
    // Sequential version
    for (pos, vel) in positions.iter_mut().zip(velocities.iter()) {
        pos.x += vel.dx;
        pos.y += vel.dy;
    }
    
    // With rayon, you'd just change iter_mut() to par_iter_mut():
    // positions.par_iter_mut()
    //     .zip(velocities.par_iter())
    //     .for_each(|(pos, vel)| {
    //         pos.x += vel.dx;
    //         pos.y += vel.dy;
    //     });
    
    println!("Processed {} entities", positions.len());
    println!("First position: ({}, {})", positions[0].x, positions[0].y);
}
```

Because DOP keeps data in contiguous arrays and ownership is clear, parallelization is often a one-line change!

---

## The Key Insight

```rust
fn main() {
    println!("DOP + Ownership = Safe Parallelism");
    println!("");
    println!("1. Data is organized by component type, not by object");
    println!("2. Systems declare exactly what they read and write");
    println!("3. The borrow checker prevents data races at compile time");
    println!("4. Non-overlapping systems can run in parallel automatically");
    println!("");
    println!("This is why Bevy can run game systems in parallel");
    println!("without explicit synchronization - the compiler guarantees safety!");
}
```

In C#, you need careful manual synchronization. In Rust with DOP, the type system does the work for you.
