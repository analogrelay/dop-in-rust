# Moves Are Free

Coming from C#, you might worry that all this moving is expensive. In C#, passing objects around is cheap (just copying a reference), but creating new objects, copying data, and cloning all trigger allocations and eventually garbage collection.

In Rust, it's the opposite: **moves are essentially free**.

---

## What Actually Happens in a Move

When you move a value in Rust, the compiler just copies the bytes and forgets about the original:

```rust
fn main() {
    let player_name = String::from("Alice");
    
    // This "move" is just copying 24 bytes (pointer, length, capacity)
    // The heap data ("Alice") doesn't move at all!
    let name = player_name;
    
    println!("{}", name);
}
```

A `String` is just three values on the stack: a pointer, a length, and a capacity. Moving it copies those 24 bytes. The actual string data on the heap stays exactly where it is.

---

## Even Better: Move Elision

Here's the secret: **most moves don't even copy bytes**. The compiler is smart.

```rust
fn create_name() -> String {
    let name = String::from("Alice");  // Created here
    name  // "Moved" to caller
}

fn main() {
    let player_name = create_name();  // Where does the String live?
    println!("{}", player_name);
}
```

In theory, `name` is created in `create_name`'s stack frame, then moved to `main`'s stack frame. In practice? The compiler uses **return value optimization** - it reserves the space for `player_name` in `main`'s stack frame as usual, and `create_name` is able to actually write it's return value directly into that space. No copying of bytes needed at all!

This works for function arguments too:

```rust
struct Player {
    name: String,
    health: i32,
}

fn process_player(p: Player) {
    println!("Processing {} with {} health", p.name, p.health);
}

fn main() {
    process_player(Player {
        name: String::from("Alice"),
        health: 100,
    });
}
```

Again, the `Player` struct is created directly in the stack space allocated for `p` inside `process_player`. No copying of bytes needed.

The "move" in the source code is a semantic concept - it tells the compiler about ownership. The actual bytes often don't move at all. Move semantics actually make these optimizations **trivial** and reliable, whereas other languages have to perform aggressive escape analysis to figure out when they can avoid copies.

**NOTE:** This is also why you'll hear people say "Rust has no ABI". The exact calling conventions and stack layouts are not part of the language specification, because the compiler is free to optimize them as it sees fit. This makes it very difficult to call Rust code that wasn't compiled together into a single binary by the exact same compiler, which makes plugin models very challenging. It's also why most Rust code is shipped as source code. Dynamic loading and reflection usually depend on artificial interfaces like exporting a C ABI from a Rust library.

---

## No Hidden Costs

In C#, passing an object to a method or returning it has hidden costs:

```csharp
// C# - what's really happening?
Player CreatePlayer(string name) {
    return new Player(name);  // Allocation!
}

void ProcessPlayer(Player p) {
    // Does ProcessPlayer retain a reference to p?
}
```

In Rust, you see exactly what happens:

```rust
struct Player {
    name: String,
    health: i32,
}

// Returns by value - but it's just copying bytes, not allocating
fn create_player(name: String) -> Player {
    Player { name, health: 100 }
}

// Takes ownership - just copies the Player struct bytes
fn process_player(p: Player) {
    println!("Processing {}", p.name);
}  // p is dropped here - memory freed

fn main() {
    let name = String::from("Alice");
    let player = create_player(name);  // name moved into function
    process_player(player);             // player moved into function
    
    // No garbage collector, no reference counting
    // Memory is freed deterministically when values are dropped
}
```

---

## Extracting Fields is a Move

You can move a field out of a struct, leaving the struct partially invalid:

```rust
struct Player {
    name: String,
    health: i32,
}

fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    // Move the name out of the player
    let extracted_name = player.name;
    
    // player.name is now invalid, but player.health is fine
    println!("Health: {}", player.health);
    println!("Name: {}", extracted_name);
}
```

This is extremely cheap - we're just moving ownership of the String, not copying any data.

But you can't use `player` as a whole anymore:

```rust
# #[derive(Debug)]
# struct Player {
#     name: String,
#     health: i32,
# }
fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    let extracted_name = player.name;
    
    println!("{:?}", player);  // ERROR: borrow of partially moved value: `player`
}
```

---

## C# Comparison

In C#, extracting a value from an object is different:

```csharp
// C# - strings are immutable and reference-counted
class Player {
    public string Name { get; set; }
    public int Health { get; set; }
}

var player = new Player { Name = "Alice", Health = 100 };
var name = player.Name;  // Now two references to the same string

// Both are still valid - but there's hidden bookkeeping
// The string stays alive until BOTH references are gone
```

Rust's move semantics mean there's always exactly one owner. No reference counting, no garbage collector deciding when to clean up.

---

## Destructuring Moves Multiple Fields

You can destructure a struct to move all its fields at once:

```rust
struct Player {
    name: String,
    health: i32,
}

fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    // Destructure - moves name, copies health (it's Copy)
    let Player { name, health } = player;
    
    println!("Name: {}, Health: {}", name, health);
    
    // player is completely consumed - all fields moved out
}
```

---

## The Mental Model

Think of Rust values as **physical objects** you hold in your hands:

- Moving is like handing someone a box - now they have it, you don't
- It's instant - no copying the contents, just transferring possession
- The contents (heap data) stay where they are inside the box

In C#, everything is more like **sticky notes with addresses**. You're not holding the object - you're holding a note that says "the real thing is at location 0x7fff42". Anyone can copy the sticky note. A cleaning service (the garbage collector) periodically checks if any sticky notes still point to each location before cleaning up.

Rust's approach is simpler and faster, but requires you to think about who holds what.
