# Repository Purpose

This repository contains materials for a 60-minute technical talk titled **"Rust for C# Developers: DOP not OOP"**.

## Talk Description

This talk helps experienced C# developers transition to Rust by reframing the learning journey around a core concept: **Data-Oriented Programming (DOP) vs Object-Oriented Programming (OOP)**.

Rather than focusing on syntax differences, the talk establishes a mental model shift:

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
├── OUTLINE.md          # Detailed talk structure and segment descriptions
├── AGENTS.md           # This file - repository purpose and conventions
├── sections/           # Individual talk sections
│   ├── 00_intro/       # Introduction section
│   │   └── 01-dop-not-oop.md   # First slide
│   ├── 01_dop_fundamentals/    # DOP fundamentals section
│   │   ├── 01-data-is-data.md  # Slides are numbered markdown files
│   │   ├── 02-enums.md
│   │   └── ...
└── README.md           # Public-facing talk description and resources
```

## Slide Format

Each "slide" is a standalone markdown file (`##-name.md`) designed to be viewed in a presentation tool that:

1. Renders the markdown content
2. Provides "compile" and "run" buttons that stitch all code blocks together into a single executable

### Slide Structure

- Alternate between explanatory markdown and code snippets
- All Rust code blocks in a single slide should combine into one valid, runnable program
- Use `---` horizontal rules to create visual breaks/sub-slides
- Order code blocks logically: types first, then impl blocks, then main()

### Example Slide Structure

```markdown
# Topic Title

Explanation of the concept...

​```rust
struct Example {
    field: i32,
}
​```

More explanation about behavior...

​```rust
impl Example {
    fn method(&self) -> i32 {
        self.field
    }
}
​```

Now let's see it in action:

​```rust
fn main() {
    let ex = Example { field: 42 };
    println!("{}", ex.method());
}
​```
```

### Code Style

- Use realistic domain models (game development, web services, data processing)
- Avoid contrived foo/bar/baz examples
- Include comments explaining *why*, not just *what*
- Show both correct code and common mistakes
- Use compiler errors to illustrate how the compiler can help you
- Errors should be annotated with comments explaining the compiler error

### Domain Consistency

Use consistent domains throughout examples for coherence:

- **Primary domain**: Game development (players, entities, systems, components)
- **Secondary domains**: Web services, data processing, file handling

### Error Examples

When showing code that doesn't compile, annotate with comments:

```rust
fn main() {
    let data = vec![1, 2, 3];
    let reference = &data[0];
    drop(data); // ERROR: cannot move out of `data` because it is borrowed
    println!("{}", reference);
}
```

## Working with AI Assistants

This repository is designed to be AI-assistant friendly. When working with Copilot, Claude, or similar tools:

### Context Documents

- **OUTLINE.md**: Detailed description of each talk segment for expansion
- **AGENTS.md** (this file): Repository conventions and structure
- Individual slide files: Should be self-contained with clear narrative flow

### Prompt Patterns

**Creating a new slide**:
> "Based on OUTLINE.md section 2.2 (Borrowing - Temporary Access), create a slide `sections/02_ownership/03-borrowing.md` that demonstrates immutable and mutable borrows with a game Player struct. Include examples of what works and what causes compiler errors. All code blocks should combine into a single runnable program."

**Reviewing consistency**:
> "Review all slides in `sections/01_dop_fundamentals/` and ensure they use consistent naming, domain concepts, and code style per AGENTS.md conventions."

## Talk Delivery Notes

### Timing

- 60 minutes total
- 5 major parts with built-in break points
- Allow 5-10 minutes for Q&A at end
- Have extra examples ready if running ahead

### Code Presentation

- Use a large, readable font (16pt+)
- Syntax highlighting essential
- Consider diff-style presentation for before/after examples
- Have compiled examples ready to run (don't compile during talk)

### Interactive Elements

- Live compilation of error examples to show compiler messages
- Ask audience prediction questions: "What do you think happens here?"
- Pause after each major part for questions
- Have backup answers for common questions

### Common Questions to Prepare For

- "When should I use Rc<RefCell<T>>?"
- "How do I model X pattern from C#?"
- "Is Rust always faster than C#?"
- "What about async/await?" (out of scope but have brief answer)
- "How long did it take you to be productive in Rust?"

## Success Criteria

Attendees should leave with:

1. **Mental Model**: Understanding that Rust is DOP not OOP
2. **Intuition**: Ability to predict what will/won't compile based on ownership
3. **Vocabulary**: Correct terminology (borrow, lifetime, trait, impl)
4. **Resources**: Know where to go next for learning
5. **Motivation**: Excitement about Rust's approach rather than intimidation

## Version History

- **v1.0**: Initial outline and structure (current)
- Future: Add slide deck, speaker notes, recorded version

## Contributing

This is a personal talk repository, but suggestions are welcome:

- Example improvements
- Additional scenarios to cover
- Corrections to technical content
- Clearer explanations

## License

Talk content and examples: MIT License (see LICENSE file)
Rust code examples follow Rust community conventions
