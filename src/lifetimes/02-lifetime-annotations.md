# Lifetime Annotations in Practice

Let's explore common lifetime patterns and how to read and write them confidently.

---

## Reading Lifetime Annotations

Lifetime syntax looks like generics, but for scopes:

```rust,noplayground
fn example<'a>(x: &'a str) -> &'a str {
    x
}
```

Read this as: "The function `example` has a lifetime parameter `'a`. It takes a reference that's valid for `'a` and returns a reference that's valid for `'a`."

The `'a` is just a name - convention uses `'a`, `'b`, `'c`, etc.

---

## Relating Multiple Inputs

When a function takes multiple references and returns one:

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

fn main() {
    let string1 = String::from("hello");
    
    {
        let string2 = String::from("world!");
        let result = longest(&string1, &string2);
        println!("Longest: {}", result);
    }
    // result is no longer valid here (string2 was dropped)
}
```

Both inputs share `'a`, so the output is valid only while BOTH inputs are valid.

---

## Different Lifetimes for Different Purposes

Sometimes inputs have independent lifetimes:

```rust
fn first_of_second<'a, 'b>(first: &'a str, second: &'b str) -> &'a str {
    // We always return from 'first', so output only needs 'a
    first
}

fn main() {
    let long_lived = String::from("I live long");
    let result;
    
    {
        let short_lived = String::from("I'm temporary");
        result = first_of_second(&long_lived, &short_lived);
        // short_lived is dropped here, but that's OK - we don't return it
    }
    
    println!("{}", result);  // Still valid!
}
```

The output lifetime `'a` is independent of `'b` because we only return from the first parameter.

---

## Structs with References

If a struct holds references, it needs lifetime parameters:

```rust
struct Excerpt<'a> {
    text: &'a str,
}

impl<'a> Excerpt<'a> {
    fn new(text: &'a str) -> Self {
        Excerpt { text }
    }
    
    fn text(&self) -> &str {
        self.text
    }
}

fn main() {
    let novel = String::from("Call me Ishmael. Some years ago...");
    let first_sentence = novel.split('.').next().unwrap();
    
    let excerpt = Excerpt::new(first_sentence);
    println!("Excerpt: {}", excerpt.text());
}
```

The `'a` says: "This `Excerpt` can't outlive the string it references."

---

## The Struct Lifetime Constraint

The lifetime ensures the struct doesn't outlive its references:

```rust
struct Excerpt<'a> {
    text: &'a str,
}

fn main() {
    let excerpt;
    
    {
        let novel = String::from("Call me Ishmael.");
        excerpt = Excerpt { text: &novel };  // ERROR: `novel` does not live long enough
    }
    
    // If this compiled, excerpt.text would be a dangling reference
    println!("{}", excerpt.text);
}
```

Here's the correct version where the data lives long enough:

```rust
struct Excerpt<'a> {
    text: &'a str,
}

fn main() {
    let novel = String::from("Call me Ishmael.");
    let excerpt = Excerpt { text: &novel };
    println!("{}", excerpt.text);
}
```

---

## The 'static Lifetime

`'static` means "lives for the entire program." String literals have this lifetime:

```rust
fn main() {
    // String literals are stored in the binary, so they're always valid
    let s: &'static str = "I live forever";
    
    println!("{}", s);
}
```

You'll also see `'static` in trait bounds, meaning "contains no non-static references":

```rust
use std::fmt::Display;

// T: Display + 'static means T implements Display AND 
// doesn't contain any references (or only 'static ones)
fn print_static<T: Display + 'static>(value: T) {
    println!("{}", value);
}

fn main() {
    print_static(42);              // OK: i32 is 'static
    print_static(String::from("hello"));  // OK: String owns its data
    
    // let s = String::from("temp");
    // let r = &s;
    // print_static(r);  // ERROR: &String is not 'static
}
```

---

## Common Lifetime Errors

### Returning references to local data

```rust
// Can't return reference to local
fn create_string() -> &str {
    let s = String::from("hello");
    &s  // ERROR: returns reference to local variable
}

fn main() {
    let s = create_string();
    println!("{}", s);
}
```

Fix: return owned data instead:

```rust
fn create_string() -> String {
    String::from("hello")
}

fn main() {
    let s = create_string();
    println!("{}", s);
}
```

---

### Reference outlives data

```rust
struct Player<'a> {
    name: &'a str,
}

fn main() {
    let player;
    
    {
        let name = String::from("Alice");
        player = Player { name: &name };  // ERROR: `name` doesn't live long enough
    }
    
    println!("Player: {}", player.name);
}
```

Fix: ensure name lives long enough:

```rust
struct Player<'a> {
    name: &'a str,
}

fn main() {
    let name = String::from("Alice");
    let player = Player { name: &name };
    println!("Player: {}", player.name);
}
```

---

## When to Own vs Borrow

If lifetime constraints get complicated, consider owning the data instead:

```rust
// With lifetime - struct borrows the string
struct ExcerptBorrowed<'a> {
    text: &'a str,
}

// Without lifetime - struct owns the string
struct ExcerptOwned {
    text: String,
}

fn main() {
    // Borrowed: lighter weight, but constrained by source lifetime
    let source = String::from("hello world");
    let borrowed = ExcerptBorrowed { text: &source };
    
    // Owned: more flexible, but involves allocation/copying
    let owned = ExcerptOwned { text: String::from("hello world") };
    
    println!("{}, {}", borrowed.text, owned.text);
}
```

Borrowing is efficient when you can; owning is simpler when lifetimes get tricky.

---

## The Mental Model

**Lifetimes are like generic type parameters, but for scopes instead of types.**

- `fn foo<T>(x: T)` - T is some type
- `fn foo<'a>(x: &'a str)` - `'a` is some scope/duration

You're telling the compiler: "These references are connected. The output is valid for this long because the input lives at least that long."

The compiler uses this information to prove your code is memory-safe at compile time.
