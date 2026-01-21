# Repository Purpose

This repository contains an mdBook site titled **"Data-Oriented Programming in Rust"**, aimed at helping C# developers transition to Rust.

## Book Description

This book helps experienced C# developers learn Rust by reframing the learning journey around a core concept: **Data-Oriented Programming (DOP) vs Object-Oriented Programming (OOP)**.

Rather than focusing on syntax differences, the book establishes a mental model shift:

- In OOP, objects encapsulate data and behavior together
- In DOP, data structures describe "what things are" and behavior is attached separately through impl blocks and traits

This paradigm shift explains why Rust feels different from C# and motivates features that initially seem restrictive (ownership, borrowing, lifetimes) as natural consequences of data-oriented thinking.

## Target Audience

**Primary**: C# developers with 3+ years of experience who are learning Rust

**Assumptions**:

- Deep familiarity with C# and OOP concepts
- Understanding of generics, interfaces, LINQ
- Some exposure to systems programming concepts helpful but not required
- May have tried Rust and found it confusing or frustrating

**Not Covered**: Basic syntax, installation, tooling setup, "Hello World" level content

## Repository Structure

```
/
├── book.toml           # mdBook configuration
├── OUTLINE.md          # Detailed chapter structure and descriptions
├── AGENTS.md           # This file - repository purpose and conventions
├── src/                # Book source content
│   ├── SUMMARY.md      # Table of contents (defines book structure)
│   ├── intro/          # Introduction chapter
│   ├── dop_fundamentals/   # DOP fundamentals section
│   ├── ownership/      # Ownership and borrowing section
│   ├── traits_generics/    # Traits and generics section
│   ├── lifetimes/      # Lifetimes section
│   ├── dyn_trait/      # Dynamic dispatch section
│   └── real_world_dop/ # Real-world patterns section
├── book/               # Generated HTML output (do not edit directly)
└── README.md           # Public-facing description and resources
```

## Building the Book

This is an [mdBook](https://rust-lang.github.io/mdBook/) project. To build and serve locally:

```bash
# Install mdBook if needed
cargo install mdbook

# Build the book
mdbook build

# Serve locally with hot reload
mdbook serve
```

The generated site will be in the `book/` directory.

## Chapter Format

Each chapter is a markdown file in the `src/` directory. Chapters are organized into sections (subdirectories) and listed in `src/SUMMARY.md`.

### Chapter Structure

- Start with a clear heading that matches the SUMMARY.md entry
- Alternate between explanatory prose and code examples
- Build concepts progressively within each chapter
- Link to related chapters where appropriate

### Code Examples

mdBook renders Rust code blocks with syntax highlighting. Use fenced code blocks:

~~~markdown
```rust
struct Player {
    name: String,
    health: i32,
}

impl Player {
    fn new(name: String) -> Self {
        Player { name, health: 100 }
    }
}

fn main() {
    let player = Player::new("Alice".to_string());
    println!("{} has {} health", player.name, player.health);
}
```
~~~

### Code Style

- Use realistic domain models (game development, web services, data processing)
- Avoid contrived foo/bar/baz examples
- Include comments explaining *why*, not just *what*
- Show both correct code and common mistakes
- Use compiler errors to illustrate how the compiler helps you

### Domain Consistency

Use consistent domains throughout examples for coherence:

- **Primary domain**: Game development (players, entities, systems, components)
- **Secondary domains**: Web services, data processing, file handling

### Error Examples

When showing code that doesn't compile, annotate with comments explaining the error:

```rust
fn main() {
    let data = vec![1, 2, 3];
    let reference = &data[0];
    drop(data); // ERROR: cannot move out of `data` because it is borrowed
    println!("{}", reference);
}
```

Use `ignore` or `compile_fail` attributes for code that shouldn't be tested:

~~~markdown
```rust,ignore
// This code demonstrates an error
```

```rust,compile_fail
// This code intentionally fails to compile
```
~~~

## Working with AI Assistants

This repository is designed to be AI-assistant friendly. When working with Copilot, Claude, or similar tools:

### Context Documents

- **OUTLINE.md**: Detailed description of each chapter for expansion
- **AGENTS.md** (this file): Repository conventions and structure
- **src/SUMMARY.md**: Book table of contents and navigation structure

### Prompt Patterns

**Creating a new chapter**:
> "Based on OUTLINE.md section 2.2 (Borrowing - Temporary Access), create a chapter `src/ownership/03-borrowing.md` that demonstrates immutable and mutable borrows with a game Player struct. Include examples of what works and what causes compiler errors."

**Adding a chapter to the book**:
> "Add a new chapter about pattern matching to the DOP Fundamentals section. Update SUMMARY.md and create the corresponding markdown file."

**Reviewing consistency**:
> "Review all chapters in `src/dop_fundamentals/` and ensure they use consistent naming, domain concepts, and code style per AGENTS.md conventions."

## Success Criteria

Readers should come away with:

1. **Mental Model**: Understanding that Rust is DOP not OOP
2. **Intuition**: Ability to predict what will/won't compile based on ownership
3. **Vocabulary**: Correct terminology (borrow, lifetime, trait, impl)
4. **Resources**: Know where to go next for learning
5. **Motivation**: Excitement about Rust's approach rather than intimidation

## Contributing

Suggestions are welcome:

- Example improvements
- Additional scenarios to cover
- Corrections to technical content
- Clearer explanations

## License

Book content and examples: MIT License (see LICENSE file)
Rust code examples follow Rust community conventions
