# The Ownership Rules

In C#, you rarely think about who "owns" data. Objects live on the heap, the garbage collector cleans them up, and references are cheap to copy. Rust doesn't work that way.

---

## The Three Rules

1. Every value has exactly **one owner**
2. When the owner goes out of scope, the value is **dropped**
3. Assignment **moves** ownership (for most types)

These rules eliminate garbage collection while preventing memory leaks and use-after-free bugs.

---

## Move Semantics: The Surprise

In C#, this code works fine - both variables reference the same object:

```csharp
var items = new List<int> { 1, 2, 3 };
var other = items;  // Both point to the same list
items.Add(4);       // Still works!
```

In Rust, assignment *moves* the value:

```rust
fn main() {
    let items = vec![1, 2, 3];
    let other = items;  // Ownership moves to `other`
    
    // items is no longer valid here!
    println!("{:?}", other);  // This works
}
```

---

## Using a Moved Value

What happens if we try to use `items` after the move?

```rust
fn main() {
    let items = vec![1, 2, 3];
    let other = items;  // Ownership moves to `other`
    
    println!("{:?}", items);  // ERROR: borrow of moved value: `items`
}
```

The compiler catches this at compile time. No null pointer exceptions, no use-after-free - just a clear error message.

---

## Why Move by Default?

This prevents a whole class of bugs:

- No dangling pointers (data freed while still referenced)
- No double frees (two owners trying to clean up)
- No data races (clear ownership = clear responsibility)

The cost? You have to think about ownership explicitly.

---

## Copy Types: The Exception

Some types are simple enough to copy cheaply. These implement the `Copy` trait:

```rust
fn main() {
    let x: i32 = 42;
    let y = x;  // Copy, not move - x is still valid!
    
    println!("x = {}, y = {}", x, y);  // Both work fine
}
```

Copy types include:

- All integer types (`i32`, `u64`, etc.)
- Floating point (`f32`, `f64`)
- `bool` and `char`
- Tuples and arrays of Copy types

---

## What Makes Something Copy?

A type can be `Copy` if it:

- Lives entirely on the stack (no heap allocations)
- Has no resources to clean up (no destructors needed)

`String` can't be `Copy` because it owns heap memory. Copying it would mean... what? Two owners of the same heap buffer? That's exactly what Rust prevents.

```rust
fn main() {
    // This is Copy - just 8 bytes on the stack
    let point: (i32, i32) = (10, 20);
    let other = point;
    println!("{:?} and {:?}", point, other);  // Both valid
}
```

But `String` is NOT Copy - it owns heap data:

```rust
fn main() {
    let name = String::from("Alice");
    let other_name = name;
    println!("{}", name);  // ERROR: borrow of moved value: `name`
}
```

---

## Functions and Ownership

Passing a value to a function also moves it:

```rust
struct Player {
    name: String,
    health: i32,
}

fn print_player(p: Player) {
    println!("{} has {} health", p.name, p.health);
}  // p is dropped here

fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    print_player(player);  // Ownership moves into the function
}
```

After the call, `player` is no longer valid:

```rust
# struct Player {
#     name: String,
#     health: i32,
# }
# fn print_player(p: Player) {
#     println!("{} has {} health", p.name, p.health);
# }
fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    print_player(player);
    print_player(player);  // ERROR: use of moved value: `player`
}
```

---

## The Mental Model Shift

**C# thinking**: "Variables are labels pointing to objects. Multiple labels can point to the same object."

**Rust thinking**: "Variables *own* values. Ownership can transfer, but there's always exactly one owner responsible for cleanup."

This isn't a limitation - it's making explicit what was always true. Someone has to be responsible for memory. In C#, it's the GC. In Rust, it's the owner.
