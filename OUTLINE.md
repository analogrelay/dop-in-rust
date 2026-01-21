# Rust for C# Developers: DOP not OOP

**Duration**: 60 minutes  
**Target Audience**: Experienced C# developers transitioning to Rust  
**Core Thesis**: Rust requires Data-Oriented Programming thinking rather than Object-Oriented Programming

---

## Talk Structure

### Opening: The DOP Thesis (3 minutes)

**Goal**: Establish the central concept - Rust separates data from behavior

**Key Points**:

- In OOP, objects encapsulate data and behavior together
- In DOP, data structures describe "what things are" and impl blocks/traits describe "what things do"
- This separation is intentional and leads to more composable, testable, and performant code

**Deliverables**:

- Side-by-side comparison of C# class vs Rust struct + impl
- Clear statement of the paradigm shift
- Promise: by the end, attendees will understand why this separation is powerful

---

## Part 1: DOP Fundamentals (12 minutes)

### 1.1 Data Structures are Just Data (4 minutes)

**Goal**: Show that Rust structs and enums are transparent data with no hidden behavior

**Key Points**:

- Structs are just fields - no constructors, no hidden state
- Enums are algebraic data types representing variants
- Pattern matching is the primary way to inspect and destructure data
- No inheritance - data composition is explicit

**Examples to Cover**:

- Basic struct definition and instantiation
- Enum with variants containing data
- Pattern matching to inspect enum variants
- Contrast with C# classes that hide implementation details

**Mental Model Shift**: "Data is transparent and inspectable. There's no 'inside' or 'outside' - just bytes in memory."

### 1.2 Behavior is Layered On (4 minutes)

**Goal**: Demonstrate how impl blocks attach behavior to data structures

**Key Points**:

- impl blocks are separate from struct definitions
- Multiple impl blocks for the same type are allowed and idiomatic
- The `self` parameter is explicit (no hidden `this`)
- Associated functions vs methods (presence of self parameter)
- Conditional compilation can add/remove behavior

**Examples to Cover**:

- Basic impl block with constructor (associated function)
- Methods with &self, &mut self, and self
- Multiple impl blocks organizing related functionality
- Conditional impl with cfg attributes

**Mental Model Shift**: "Behavior is not 'part of' the object. It's attached to the data type and can be organized however makes sense."

---

## Part 2: Ownership - The Cost of Separation (15 minutes)

### 2.1 The Ownership Rules (3 minutes)

**Goal**: Introduce the three ownership rules and show how they differ from C# reference semantics

**Key Points**:

- Every value has exactly one owner
- When the owner goes out of scope, the value is dropped
- Assignment moves ownership (except for Copy types)
- C# developers expect reference semantics everywhere - Rust doesn't work that way

**Examples to Cover**:

- Move semantics with String (heap-allocated type)
- Copy semantics with i32 (stack-allocated type)
- The Copy trait and what it means
- Common beginner error: using a value after it's been moved

**Mental Model Shift**: "You can't reason about 'objects' anymore. You must reason about who OWNS the data and when ownership transfers."

### 2.2 Borrowing - Temporary Access (5 minutes)

**Goal**: Show how borrowing provides temporary access without transferring ownership

**Key Points**:

- Immutable borrows (&T) allow read-only access
- Mutable borrows (&mut T) allow read-write access
- The aliasing XOR mutability rule prevents data races at compile time
- Function signatures document ownership and borrowing relationships

**Examples to Cover**:

- Function taking &T (immutable borrow)
- Function taking &mut T (mutable borrow)
- Multiple immutable borrows are allowed
- Only one mutable borrow at a time
- Can't have mutable and immutable borrows simultaneously
- Common borrow checker errors and how to fix them

**Mental Model Shift**: "Borrowing is like loaning someone a book. You still own it, but they can read it. Mutable borrowing is like loaning someone your only pen - nobody else can use it while they have it."

### 2.3 Data Structure Design with Ownership (7 minutes)

**Goal**: Demonstrate how ownership influences data structure design choices

**Key Points**:

- Traditional OOP patterns (trees, graphs) fight the borrow checker
- Arena allocation and index-based references work with ownership
- Interior mutability (Cell, RefCell) trades compile-time for runtime checks
- Smart pointers (Box, Rc, Arc) have specific use cases
- DOP encourages designs that make ownership explicit

**Examples to Cover**:

- Traditional tree structure with Box (ownership chain)
- Graph structure using arena allocation and indices
- When to use Rc<RefCell<T>> (sparingly)
- Entity-Component pattern as an alternative to object hierarchies

**Mental Model Shift**: "Don't fight the borrow checker. Design data structures that express ownership clearly. This often leads to better architecture."

---

## Part 3: Data-Oriented Design in Practice (12 minutes)

### 3.1 Designing Composable Types (4 minutes)

**Goal**: Encourage creating purpose-built types rather than reusing generic ones

**Key Points**:

- Don't be afraid to create many small, focused types
- Each type should represent one clear concept in your domain
- Memory allocation isn't the enemy - clarity and correctness are more valuable
- Composition over inheritance: build complex types from simple ones
- Rust's zero-cost abstractions mean small types compile to efficient code

**Examples to Cover**:

- Breaking a monolithic "Entity" struct into focused component types
- Composing complex game state from simple building blocks
- C# instinct: reuse one class with optional fields vs Rust approach: separate types
- How the compiler optimizes away the abstraction overhead

**Mental Model Shift**: "Types are cheap. Create as many as you need to accurately model your domain. The compiler will optimize; your job is clarity."

### 3.2 Immutability and Transformation (4 minutes)

**Goal**: Show the power of immutable data with transformation functions

**Key Points**:

- Default to immutable data (`let` not `let mut`)
- Transform data by creating new values rather than mutating in place
- Immutability makes code easier to reason about and parallelize
- Method chaining with owned values enables fluent APIs
- When mutation is needed, make it explicit and localized

**Examples to Cover**:

- Transforming game state: old state → function → new state
- Builder pattern using owned self for method chaining
- Contrast: C# mutable object vs Rust transformation pipeline
- When mutation is appropriate (performance-critical inner loops)

**Mental Model Shift**: "Instead of 'change this object', think 'create a new value based on this one'. Data flows through transformations."

### 3.3 Newtypes for Type Safety (4 minutes)

**Goal**: Demonstrate how wrapper types prevent bugs at compile time

**Key Points**:

- Newtypes wrap existing types to create distinct type identities
- Prevents mixing up values that have the same underlying type
- Zero runtime cost - the wrapper is optimized away
- Makes function signatures self-documenting
- Catches entire categories of bugs at compile time

**Examples to Cover**:

- PlayerId vs EnemyId vs ItemId (all wrap u32, but can't be confused)
- Health vs Damage vs Mana (semantic meaning enforced by types)
- Function that takes (PlayerId, EnemyId) can't be called with arguments swapped
- Contrast with C# where you might use int for everything

**Mental Model Shift**: "If two values mean different things, they should be different types - even if they're stored the same way. Let the compiler catch your mistakes."

---

## Part 4: Traits and Generics (12 minutes)

### 4.1 Traits as Shared Behavior (4 minutes)

**Goal**: Introduce traits as contracts for behavior that types can implement

**Key Points**:

- Traits define what methods a type must provide
- Similar to C# interfaces, but more powerful
- Traits can have default implementations
- Types implement traits explicitly with `impl Trait for Type`
- Traits enable code reuse without inheritance

**Examples to Cover**:

- Defining a simple trait (e.g., `Damageable` for game entities)
- Implementing the trait for different types
- Using default method implementations
- Contrast with C# interfaces and abstract classes

**Mental Model Shift**: "Traits describe capabilities, not identity. A type can have many capabilities without forming an inheritance hierarchy."

### 4.2 Generics and Trait Bounds (5 minutes)

**Goal**: Show how generics use trait bounds to constrain types at compile time

**Key Points**:

- Rust generics are monomorphized (compile-time specialization)
- Trait bounds specify what capabilities a generic type must have
- Each concrete type gets its own specialized implementation
- This is "zero-cost abstraction" - no runtime overhead
- Trade-off: longer compile times and larger binaries

**Examples to Cover**:

- Generic function with trait bounds (`fn process<T: Damageable>(target: &mut T)`)
- Multiple trait bounds with `+` syntax
- `where` clauses for complex bounds
- How monomorphization generates specialized code
- Comparison with C# generics (reified, runtime type checking)

**Mental Model Shift**: "Generics aren't magic runtime polymorphism. They're code generation templates. The compiler writes specialized code for each type you use."

### 4.3 Conditional Implementations (3 minutes)

**Goal**: Demonstrate implementing traits conditionally based on type parameters

**Key Points**:

- Traits can be implemented conditionally based on bounds
- Blanket implementations provide behavior for many types at once
- This enables powerful composition patterns
- Standard library uses this extensively

**Examples to Cover**:

- Conditional impl based on trait bounds (`impl<T: Display> MyType<T>`)
- Blanket implementations (`impl<T: Display> ToString for T`)
- How the orphan rule prevents conflicts
- Building capability through composition

**Mental Model Shift**: "Implementations can be conditional on properties of your data types. Behavior emerges from the combination of types and their capabilities."

---

## Part 5: Lifetimes - Making Data Relationships Explicit (10 minutes)

### 5.1 Why Lifetimes Exist (3 minutes)

**Goal**: Motivate lifetime annotations by showing what problem they solve

**Key Points**:

- References must always point to valid data
- The borrow checker needs to prove references don't outlive their data
- Lifetime annotations describe relationships between references
- They're descriptive, not prescriptive (you're telling the compiler what's already true)

**Examples to Cover**:

- Dangling reference error
- Simple function returning a reference
- Why the compiler needs lifetime annotations
- Lifetime elision rules (when you don't need to write them)

**Mental Model Shift**: "Lifetimes make the invisible visible. C# hides reference validity behind GC. Rust makes you document it."

### 5.2 Lifetime Annotations in Practice (7 minutes)

**Goal**: Show common lifetime patterns and how to read/write them

**Key Points**:

- Lifetime parameters are generic over scope durations
- Input and output lifetimes can be related
- Structs with references need lifetime parameters
- Multiple lifetimes when references have different sources
- Common patterns: 'a, 'static

**Examples to Cover**:

- Function with single lifetime parameter
- Function relating input and output lifetimes
- Struct holding references with lifetime parameter
- Multiple lifetime parameters when needed
- The 'static lifetime for string literals
- Common lifetime errors and solutions

**Mental Model Shift**: "Lifetime parameters are like generic type parameters, but for scopes instead of types. You're telling the compiler how long references need to remain valid."

---

## Part 6: Dynamic Dispatch with dyn Trait (5 minutes)

### 6.1 When You Actually Need Runtime Polymorphism (5 minutes)

**Goal**: Show that dyn Trait has a narrow but important use case

**Key Points**:

- Most Rust code uses static dispatch (generics) - this is the default
- `dyn Trait` is for when you genuinely don't know types at compile time
- Common use cases: plugin systems, heterogeneous collections, trait objects in return types
- Requires pointer indirection (`Box<dyn Trait>`, `&dyn Trait`, `Arc<dyn Trait>`)
- Has runtime cost: vtable lookup, no inlining, cache misses
- Object safety rules restrict which traits can be used

**Examples to Cover**:

- Heterogeneous collection: `Vec<Box<dyn Drawable>>` for different entity types
- Plugin architecture where types aren't known until runtime
- Why you can't have `Vec<dyn Trait>` (unsized type)
- Object safety: why `Clone` isn't object-safe (returns `Self`)

**When NOT to Use dyn Trait**:

- If you know all types at compile time, use generics or enums
- If you have a fixed set of variants, an enum is usually better
- Don't use it just because it "feels like" C# interfaces

**Mental Model Shift**: "Dynamic dispatch is a specialized tool, not the default. In C#, interfaces are everywhere. In Rust, `dyn Trait` is rare - reach for generics or enums first."

---

## Part 7: Real-World DOP (5 minutes)

**Goal**: Show how DOP manifests in real Rust codebases

**Key Points**:

- Entity-Component-System (ECS) architecture is pure DOP
- Game engines like Bevy embrace data-oriented design
- Parallelism is easier when data ownership is explicit

**Examples to Cover**:

- Simple ECS pattern with components
- System functions operating on component slices
- Why this pattern is popular in high-performance Rust

**Mental Model Shift**: "DOP isn't just 'how Rust works' - it's often the optimal way to structure high-performance code."

---

## Closing: The DOP Mindset (5 minutes)

**Goal**: Send attendees away with actionable principles for thinking in DOP

**Key Takeaways**:

1. Design data first - what information do you need and how should it be laid out?
2. Add behavior second - what operations make sense on this data?
3. Compose with traits - how do different pieces of behavior combine?
4. Think about ownership - who owns this data, who borrows it, for how long?
5. Let the borrow checker guide you toward better designs

**Reframe the "Restrictions"**:

- Ownership isn't restrictive - it makes memory management explicit
- Borrowing rules prevent entire classes of bugs at compile time
- Lifetimes document what was always true but hidden
- The compiler is your pair programmer who never gets tired

**Resources**:

- "Data-Oriented Design" by Richard Fabian
- The Rust Book (especially ownership chapters)
- Bevy game engine for DOP in practice
- "Rust for Rustaceans" for advanced patterns

**Final Thought**: "DOP forces you to think about your data differently. This feels restrictive at first, but it leads to code that's easier to reason about, parallelize, and optimize. Welcome to thinking in data."

---

## Example Code Requirements

Each major section should have runnable examples in an `examples/` directory:

- Examples should be complete with main() functions
- Each example should compile and run successfully
- Examples should progressively build on each other
- Include examples of common errors with comments explaining why they fail
- All examples should use realistic domain models (games, web services, etc.) not contrived foo/bar

## Presentation Notes

- Keep slides minimal - code should be the focus
- Live coding demonstrations where appropriate (especially borrow checker errors)
- Have backup pre-written code in case live coding goes wrong
- Use consistent domain (game development) throughout for cohesion
- Pause for questions after each major part
- Emphasize that the goal is not to memorize rules but to develop intuition
