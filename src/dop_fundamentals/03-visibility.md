# Visibility and Encapsulation

Rust still has encapsulation, but it works differently than C#.

```rust,noplayground
mod game {
    pub struct Player {
        health: i32,       // private to this module
        pub name: String,  // visible outside this module
    }

    impl Player {
        pub fn new(name: String) -> Player {
            Player { name, health: 100 }
        }

        pub fn health(&self) -> i32 {
            self.health
        }
    }
}
```

The visibility modifiers map like this:

| C# | Rust | Visible to... |
| --- | --- | --- |
| `private` | *(default)* | Same module (and child modules) |
| `internal` | `pub(crate)` | Same crate |
| `public` | `pub` | Everyone |

---

## Module-Private vs Class-Private

The key difference: Rust's default visibility is **module-private**, not class-private.

```rust
# mod game {
#     pub struct Player {
#         health: i32,
#         pub name: String,
#     }
#
#     impl Player {
#         pub fn new(name: String) -> Player {
#             Player { name, health: 100 }
#         }
#
#         pub fn health(&self) -> i32 {
#             self.health
#         }
#     }
# }
#
fn main() {
    let player = game::Player::new(String::from("Alice"));
    
    // This works - name is pub
    println!("Name: {}", player.name);
    
    // This works - we have a public accessor
    println!("Health: {}", player.health());
    
    // This would fail - health is private to the game module:
    println!("Direct health: {}", player.health);
}
```

This encourages organizing related code into modules rather than hiding everything inside individual types. It also encourages thinking locally about visibility. Think about whether a given struct/enum/function/module needs to be visible outside its module. Then, think about your public API surface in the `lib.rs` at the top.
