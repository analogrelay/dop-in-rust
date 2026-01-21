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

However, this table is somewhat misleading - Rust's visibility modifiers really aren't like C#'s. In C#, visibility is tied to classes and assemblies. In Rust, visibility is based almost exclusively on **modules**. The default is module-private, and `pub` makes things visible outside the module.

The `pub(crate)` modifier is somewhat of an escape hatch for situations where you can't easily express visibility using just the module hierarchy. In practice, if you have internal APIs that should be visible across your crate but not exported publicly, it's often better to organize them into a private module in your crate and export the necessary APIs as `pub` from that module, rather than liberally using `pub(crate)` everywhere.

Think about visibility in terms of module boundaries first, and your public API surface in `lib.rs` at the top.

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
