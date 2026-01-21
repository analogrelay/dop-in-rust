# Borrowing: Temporary Access

Moving ownership everywhere would be impractical. You'd have to return values from every function just to keep using them. Borrowing solves this.

---

## References: Borrowing Without Taking

A reference lets you *borrow* a value without taking ownership:

```rust
struct Player {
    name: String,
    health: i32,
}

fn print_player(p: &Player) {  // Takes a reference
    println!("{} has {} health", p.name, p.health);
}  // p goes out of scope, but it was just borrowing - nothing is dropped

fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    print_player(&player);  // Lend the player
    print_player(&player);  // Can lend again - we still own it!
    
    println!("Still ours: {}", player.name);
}
```

The `&` means "borrow" - you can look, but you don't own it.

---

## Immutable Borrows

By default, borrows are immutable - you can read but not modify:

```rust
struct Player {
    name: String,
    health: i32,
}

fn try_to_damage(p: &Player) {
    // p.health -= 10;  // ERROR: cannot assign to `p.health`, which is behind a `&` reference
    println!("{} has {} health", p.name, p.health);
}

fn main() {
    let player = Player {
        name: String::from("Alice"),
        health: 100,
    };
    
    try_to_damage(&player);
}
```

---

## Mutable Borrows

To modify borrowed data, you need a *mutable* borrow:

```rust
struct Player {
    name: String,
    health: i32,
}

fn damage(p: &mut Player, amount: i32) {
    p.health -= amount;
    println!("{} takes {} damage, now at {} health", 
             p.name, amount, p.health);
}

fn main() {
    let mut player = Player {  // Note: the binding must also be mut
        name: String::from("Alice"),
        health: 100,
    };
    
    damage(&mut player, 30);
    damage(&mut player, 25);
    
    println!("Final health: {}", player.health);
}
```

Two requirements:

1. The variable must be declared `mut`
2. The borrow must be `&mut`

---

## The Aliasing XOR Mutability Rule

Here's the key insight: You can have **either**:

- Any number of immutable borrows (`&T`), **OR**
- Exactly one mutable borrow (`&mut T`)

But never both at the same time.

```rust
fn main() {
    let mut data = vec![1, 2, 3];
    
    let r1 = &data;      // Immutable borrow - OK
    let r2 = &data;      // Another immutable borrow - OK
    println!("{:?} {:?}", r1, r2);  // Using both - OK
    
    let r3 = &mut data;  // Mutable borrow - OK (r1 and r2 are no longer used)
    r3.push(4);
    println!("{:?}", r3);
}
```

---

## Why This Rule?

This rule prevents data races at compile time:

```rust
fn main() {
    let mut data = vec![1, 2, 3];
    
    let r1 = &data;       // Immutable borrow
    let r2 = &mut data;   // ERROR: cannot borrow `data` as mutable because 
                          // it is also borrowed as immutable
    
    println!("{:?}", r1); // r1 is still in use here
}
```

If this compiled, `r2` could modify the vector while `r1` is reading it. The compiler prevents this entirely.

---

## Borrow Scopes: Non-Lexical Lifetimes

Borrows end when they're last used, not at the end of the block:

```rust
fn main() {
    let mut data = vec![1, 2, 3];
    
    let r1 = &data;
    println!("{:?}", r1);  // Last use of r1
    
    // r1's borrow ends here, so we can now mutate
    let r2 = &mut data;
    r2.push(4);
    println!("{:?}", r2);
}
```

The compiler tracks where borrows are actually used, not just where variables are declared.

---

## Common Borrow Checker Errors

### Borrowing while iterating

```rust
fn main() {
    let mut items = vec![1, 2, 3, 4, 5];
    
    for item in &items {
        if *item == 3 {
            // items.push(6);  // ERROR: cannot borrow `items` as mutable
                               // because it is also borrowed as immutable
        }
    }
    
    // Fix: collect what to do, then do it
    let should_add = items.iter().any(|&x| x == 3);
    if should_add {
        items.push(6);
    }
    println!("{:?}", items);
}
```

---

### Returning references to local data

```rust
struct Player {
    name: String,
    health: i32,
}

// This won't compile - think about why
// fn create_player() -> &Player {
//     let p = Player { 
//         name: String::from("Alice"), 
//         health: 100 
//     };
//     &p  // ERROR: returns a reference to data owned by the current function
// }

// Fix: return the owned value
fn create_player() -> Player {
    Player { 
        name: String::from("Alice"), 
        health: 100 
    }
}

fn main() {
    let player = create_player();
    println!("{}", player.name);
}
```

---

## The Borrowing Mental Model

Think of it like a library:

- **Owning** = You bought the book. You can read it, write in it, or throw it away.
- **Immutable borrow** (`&T`) = You borrowed the book from the library. Others can borrow it too. You can read it but not write in it.
- **Mutable borrow** (`&mut T`) = You have exclusive checkout. No one else can borrow it while you have it, but you can write in it.

The library (compiler) enforces these rules to prevent chaos.
