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

Rust's visibility modifiers work very differently from C#'s. In C#, visibility is tied to classes and assemblies (`private`, `internal`, `public`). In Rust, visibility is based almost exclusively on **modules**.

The default in Rust is **module-private** - items are visible within their module and any child modules. Adding `pub` makes an item visible outside its module. This is fundamentally different from C#'s class-based privacy model.

Rust also has `pub(crate)`, which makes items visible throughout the current crate but not to external crates. However, this is somewhat of an escape hatch for situations where you can't easily express visibility using just the module hierarchy. In practice, if you have internal APIs that should be visible across your crate but not exported publicly, it's often better to organize them into a private module in your crate and export the necessary APIs as `pub` from that module, rather than liberally using `pub(crate)` everywhere.

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
