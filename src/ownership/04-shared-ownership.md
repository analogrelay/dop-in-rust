# Shared Ownership

Sometimes you genuinely need multiple owners of the same data. Rust provides escape hatches for this - but they come with trade-offs.

---

## Rc: Reference Counting (Single-Threaded)

`Rc<T>` (Reference Counted) allows multiple owners of the same data:

```rust
use std::rc::Rc;

fn main() {
    let data = Rc::new(vec![1, 2, 3]);
    
    let owner1 = Rc::clone(&data);  // Increment reference count
    let owner2 = Rc::clone(&data);  // Increment again
    
    println!("Reference count: {}", Rc::strong_count(&data));  // 3
    println!("All see same data: {:?}", owner2);
    
    drop(owner1);
    println!("After drop: {}", Rc::strong_count(&data));  // 2
}
// data is freed when the last Rc is dropped
```

`Rc::clone` doesn't clone the data - it just increments the count. Cheap!

---

## The Catch: Rc is Immutable

`Rc` gives you shared ownership, but the data is immutable:

```rust
use std::rc::Rc;

fn main() {
    let data = Rc::new(vec![1, 2, 3]);
    
    data.push(4);  // ERROR: cannot borrow as mutable
    
    println!("{:?}", data);
}
```

Multiple owners means we can't have `&mut` - that would violate the borrowing rules!

---

## RefCell: Runtime Borrow Checking

`RefCell<T>` moves borrow checking from compile time to runtime:

```rust
use std::cell::RefCell;

fn main() {
    let data = RefCell::new(vec![1, 2, 3]);
    
    // Borrow mutably at runtime
    data.borrow_mut().push(4);
    data.borrow_mut().push(5);
    
    // Borrow immutably to read
    let borrow1 = data.borrow();
    println!("{:?}", borrow1);  // [1, 2, 3, 4, 5]

    let borrow2 = data.borrow_mut();  // PANIC: already borrowed!
    
    // This is here to keep the first borrow alive
    println!("{:?}", borrow1);
}
```

This is a runtime panic, not a compile error. You've traded safety guarantees for flexibility.

---

## Rc + RefCell: Shared Mutable State

Combine them for multiple owners with mutation:

```rust
use std::rc::Rc;
use std::cell::RefCell;

fn main() {
    let shared = Rc::new(RefCell::new(vec![1, 2, 3]));
    
    let owner1 = Rc::clone(&shared);
    let owner2 = Rc::clone(&shared);
    
    // Either owner can mutate
    owner1.borrow_mut().push(4);
    owner2.borrow_mut().push(5);
    
    println!("{:?}", shared.borrow());  // [1, 2, 3, 4, 5]
}
```

This is Rust's closest equivalent to C#'s reference semantics. Use sparingly - you're opting out of compile-time safety.

---

## Arc: Thread-Safe Reference Counting

`Rc` is not thread-safe. For multi-threaded code, use `Arc` (Atomic Reference Counted):

```rust
use std::sync::Arc;
use std::thread;

fn main() {
    let data = Arc::new(vec![1, 2, 3]);
    
    let data_clone = Arc::clone(&data);
    let handle = thread::spawn(move || {
        println!("From thread: {:?}", data_clone);
    });
    
    println!("From main: {:?}", data);
    handle.join().unwrap();
}
```

`Arc` has slightly more overhead than `Rc` (atomic operations), so use `Rc` when you don't need thread safety.

---

## Arc is Also Immutable

Just like `Rc`, `Arc` only gives you shared immutable access, because we need to protect against data races:

```rust,noplayground
use std::sync::Arc;

fn main() {
    let data = Arc::new(vec![1, 2, 3]);
    
    data.push(4);  // ERROR: cannot borrow as mutable
}
```

For thread-safe mutation, you need a lock.

---

## Mutex: Mutual Exclusion

`Mutex<T>` provides exclusive access across threads:

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("Final count: {}", *counter.lock().unwrap());  // 10
}
```

`lock()` blocks until you have exclusive access. The lock is released when the guard is dropped.

**NOTE**: Unlike in C#, locks in Rust wrap the data to be protected by the lock. This ensures that you must hold the lock to access the data and that the lock will automatically be released when you're done.

---

## RwLock: Multiple Readers OR One Writer

`RwLock<T>` allows many readers or one writer (like the borrow rules!):

```rust
use std::sync::{Arc, RwLock};
use std::thread;

fn main() {
    let data = Arc::new(RwLock::new(vec![1, 2, 3]));
    
    // Multiple readers can access simultaneously
    let data1 = Arc::clone(&data);
    let data2 = Arc::clone(&data);
    
    let reader1 = thread::spawn(move || {
        let read = data1.read().unwrap();
        println!("Reader 1: {:?}", *read);
    });
    
    let reader2 = thread::spawn(move || {
        let read = data2.read().unwrap();
        println!("Reader 2: {:?}", *read);
    });
    
    // Writer needs exclusive access
    {
        let mut write = data.write().unwrap();
        write.push(4);
        println!("Writer added 4");
    }
    
    reader1.join().unwrap();
    reader2.join().unwrap();
}
```

Use `RwLock` when reads are much more common than writes. Rust's immutable/mutable borrowing rules help enforce safe access patterns here. The compiler will not allow you to mutate data within an `RwLock` unless you hold the write lock.

---

## The Hierarchy of Escape Hatches

| Need | Single-Threaded | Multi-Threaded |
|------|-----------------|----------------|
| Shared ownership | `Rc<T>` | `Arc<T>` |
| Interior mutability | `RefCell<T>` | `Mutex<T>` / `RwLock<T>` |
| Both | `Rc<RefCell<T>>` | `Arc<Mutex<T>>` / `Arc<RwLock<T>>` |

---

## When to Use These

**Prefer normal ownership and borrowing.** These types are escape hatches, not defaults.

Good uses:

- Graph structures with cycles
- Shared configuration across a system
- Caches that multiple components read/write
- Thread-safe shared state

Code smells:

- Using `Rc<RefCell<T>>` everywhere
- Fighting the borrow checker on every function
- Runtime panics from RefCell violations

If you're reaching for these constantly, consider whether a different design (like arenas with indices) might work better.
