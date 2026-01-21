# Dynamic Dispatch with dyn Trait

So far, all our polymorphism has been resolved at compile time. But sometimes you genuinely don't know the concrete type until runtime. That's where `dyn Trait` comes in - but use it sparingly.

---

## The Problem: Heterogeneous Collections

With generics, every element in a collection must be the same type:

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle { radius: f32 }
struct Rectangle { width: f32, height: f32 }

impl Drawable for Circle {
    fn draw(&self) { println!("Drawing circle with radius {}", self.radius); }
}

impl Drawable for Rectangle {
    fn draw(&self) { println!("Drawing {}x{} rectangle", self.width, self.height); }
}

fn main() {
    // This works - all the same type
    let circles: Vec<Circle> = vec![
        Circle { radius: 1.0 },
        Circle { radius: 2.0 },
    ];
    
    // But what if we want mixed shapes?
    // let shapes: Vec<???> = vec![Circle { ... }, Rectangle { ... }];
    
    for c in &circles {
        c.draw();
    }
}
```

Generics can't help here - we need different types in the same collection.

---

## dyn Trait: Runtime Polymorphism

`dyn Trait` creates a *trait object* - a pointer plus a vtable:

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle { radius: f32 }
struct Rectangle { width: f32, height: f32 }

impl Drawable for Circle {
    fn draw(&self) { println!("Drawing circle with radius {}", self.radius); }
}

impl Drawable for Rectangle {
    fn draw(&self) { println!("Drawing {}x{} rectangle", self.width, self.height); }
}

fn main() {
    // Box<dyn Drawable> = owned pointer to "something that implements Drawable"
    let shapes: Vec<Box<dyn Drawable>> = vec![
        Box::new(Circle { radius: 1.0 }),
        Box::new(Rectangle { width: 2.0, height: 3.0 }),
        Box::new(Circle { radius: 0.5 }),
    ];
    
    for shape in &shapes {
        shape.draw();  // Dynamic dispatch - resolved at runtime
    }
}
```

Now we can mix types! The cost: runtime dispatch instead of compile-time.

---

## Why the Box?

`dyn Trait` is *unsized* - the compiler doesn't know how big it is. You need a pointer:

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle { radius: f32 }
impl Drawable for Circle {
    fn draw(&self) { println!("Circle"); }
}

fn main() {
    // These work - pointer types
    let _boxed: Box<dyn Drawable> = Box::new(Circle { radius: 1.0 });
    
    let circle = Circle { radius: 1.0 };
    let _borrowed: &dyn Drawable = &circle;
    
    // This doesn't work - unsized!
    // let direct: dyn Drawable = Circle { radius: 1.0 };  
    // ERROR: the size of `dyn Drawable` cannot be statically determined
}
```

Common pointer types for trait objects:

- `Box<dyn Trait>` - owned, heap-allocated
- `&dyn Trait` - borrowed reference
- `Arc<dyn Trait>` - shared ownership (thread-safe)

---

## How It Works: The Vtable

A trait object is two pointers: one to the data, one to a vtable:

```
Box<dyn Drawable>
┌─────────────────┐
│ data pointer    │ ──► Circle { radius: 1.0 }
├─────────────────┤
│ vtable pointer  │ ──► ┌─────────────────────┐
└─────────────────┘     │ draw: Circle::draw  │
                        │ drop: Circle::drop  │
                        │ size: 4 bytes       │
                        └─────────────────────┘
```

When you call `shape.draw()`, the runtime looks up the function in the vtable. This is just like C# interface dispatch.

---

## The Runtime Cost

Dynamic dispatch has real overhead:

```rust
use std::time::Instant;

trait Processable {
    fn process(&self) -> i64;
}

struct Data { value: i64 }
impl Processable for Data {
    fn process(&self) -> i64 { self.value * 2 }
}

// Static dispatch - compiler inlines this
fn process_static<T: Processable>(items: &[T]) -> i64 {
    items.iter().map(|x| x.process()).sum()
}

// Dynamic dispatch - vtable lookup each iteration
fn process_dynamic(items: &[Box<dyn Processable>]) -> i64 {
    items.iter().map(|x| x.process()).sum()
}

fn main() {
    // Size difference
    println!("Size of Data: {} bytes", std::mem::size_of::<Data>());
    println!("Size of Box<dyn Processable>: {} bytes (pointer + vtable pointer)", 
             std::mem::size_of::<Box<dyn Processable>>());
    println!();

    // Create test data
    let data: Vec<Data> = (0..100_000).map(|i| Data { value: i }).collect();
    let boxed: Vec<Box<dyn Processable>> = (0..100_000)
        .map(|i| Box::new(Data { value: i }) as Box<dyn Processable>)
        .collect();
    
    // Benchmark static dispatch
    let start = Instant::now();
    let mut result = 0;
    for _ in 0..100 {
        result = process_static(&data);
    }
    let static_time = start.elapsed();
    println!("Static dispatch:  {:?} (result: {})", static_time, result);
    
    // Benchmark dynamic dispatch  
    let start = Instant::now();
    let mut result = 0;
    for _ in 0..100 {
        result = process_dynamic(&boxed);
    }
    let dynamic_time = start.elapsed();
    println!("Dynamic dispatch: {:?} (result: {})", dynamic_time, result);
}
```

Static dispatch: direct call, can be inlined, cache-friendly.
Dynamic dispatch: vtable lookup, no inlining, pointer chasing.

---

## Object Safety

Not all traits can be used as `dyn Trait`. A trait is *object-safe* if:

1. It doesn't return `Self`
2. It doesn't have generic methods
3. It doesn't require `Self: Sized`

```rust
// Object-safe: can be used as dyn Drawable
trait Drawable {
    fn draw(&self);
}

// NOT object-safe: returns Self
trait Clonable {
    fn clone(&self) -> Self;  // How big is the return value? Unknown!
}

// NOT object-safe: generic method
trait Processor {
    fn process<T>(&self, item: T);  // Which version goes in the vtable?
}

fn main() {
    // let x: Box<dyn Clonable>;  // ERROR: the trait `Clonable` cannot be made into an object
    println!("Object safety matters!");
}
```

Essentially, any method that requires concrete knowledge of the type at compile time makes the trait non-object-safe. Returning `Self` requires that the compiler know how big the return type is. Generic methods require recompiling code for each possible type parameter (impossible when we don't know the type at runtime). Trait objects are inherently unsized, so requiring `Self: Sized` is a contradiction. Object-safe traits must look a lot like interfaces in C#, which are **always** object-safe.

The compiler tells you when a trait isn't object-safe if you try to make a `dyn` pointer to it. If you want to use such a trait as a trait object, you'll need to redesign it.

---

## When to Use dyn Trait

✅ **Good use cases**:

- Plugin systems where types aren't known at compile time
- Heterogeneous collections (mixed types)
- Reducing binary size (one function instead of many monomorphized versions)
- Recursive types that would otherwise have infinite size

```rust
trait Plugin {
    fn name(&self) -> &str;
    fn execute(&self);
}

struct PluginManager {
    #[allow(dead_code)]
    plugins: Vec<Box<dyn Plugin>>,  // Unknown plugins loaded at runtime
}

fn main() {
    println!("Plugin systems are a good use case for dyn Trait");
}
```

---

## When NOT to Use dyn Trait

❌ **Use generics instead** when you know types at compile time:

```rust
trait Drawable {
    fn draw(&self);
}

struct Circle { radius: f32 }
impl Drawable for Circle {
    fn draw(&self) { println!("Circle: {}", self.radius); }
}

// Bad: unnecessary dynamic dispatch
#[allow(dead_code)]
fn draw_bad(shape: &dyn Drawable) {
    shape.draw();
}

// Good: static dispatch, can be inlined
fn draw_good<T: Drawable>(shape: &T) {
    shape.draw();
}

fn main() {
    let c = Circle { radius: 1.0 };
    draw_good(&c);  // Works, faster
}
```

---

## When NOT to Use dyn Trait (continued)

❌ **Use an enum instead** when you have a fixed set of variants:

```rust
// Instead of dyn Trait for a known set of shapes...
enum Shape {
    Circle { radius: f32 },
    Rectangle { width: f32, height: f32 },
    Triangle { base: f32, height: f32 },
}

impl Shape {
    fn draw(&self) {
        match self {
            Shape::Circle { radius } => println!("Circle: {}", radius),
            Shape::Rectangle { width, height } => println!("Rect: {}x{}", width, height),
            Shape::Triangle { base, height } => println!("Triangle: {}x{}", base, height),
        }
    }
    
    fn area(&self) -> f32 {
        match self {
            Shape::Circle { radius } => 3.14159 * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle { base, height } => 0.5 * base * height,
        }
    }
}

fn main() {
    let shapes = vec![
        Shape::Circle { radius: 1.0 },
        Shape::Rectangle { width: 2.0, height: 3.0 },
    ];
    
    for shape in &shapes {
        shape.draw();
        println!("  Area: {}", shape.area());
    }
}
```

Enums are faster (no vtable), exhaustive (compiler checks all cases), and sized.

---

## The Mental Model

**C# thinking**: "Interfaces are everywhere. I use them for abstraction, testing, dependency injection..."

**Rust thinking**: "Dynamic dispatch is a specialized tool. I use generics by default. I use enums for closed sets of variants. I use `dyn Trait` only when I genuinely don't know the type at compile time."

Most Rust code uses zero `dyn Trait`. It's not wrong to use it - but it shouldn't be your first instinct coming from C#.
