# Data Structure Design with Ownership

The borrow checker isn't just a hurdle - it's a design tool. Some patterns that work in C# fight against Rust's ownership model. Let's explore patterns that work *with* the borrow checker.

---

## The Problem: Shared Mutable State

In C#, this tree structure is natural:

```csharp
class Node {
    public int Value;
    public Node Parent;      // Reference to parent
    public List<Node> Children;  // References to children
}
```

Every node can reference its parent and children. Mutations anywhere are visible everywhere.

In Rust, this is... complicated. Who owns each node? Multiple references pointing everywhere violates the ownership rules.

---

## Option 1: Ownership Chains with Box

For trees with clear parent-to-child ownership:

```rust
struct TreeNode {
    value: i32,
    children: Vec<Box<TreeNode>>,  // Parent owns children
}

impl TreeNode {
    fn new(value: i32) -> Self {
        TreeNode { value, children: vec![] }
    }
    
    fn add_child(&mut self, value: i32) {
        self.children.push(Box::new(TreeNode::new(value)));
    }
    
    fn sum(&self) -> i32 {
        self.value + self.children.iter().map(|c| c.sum()).sum::<i32>()
    }
}

fn main() {
    let mut root = TreeNode::new(1);
    root.add_child(2);
    root.add_child(3);
    root.children[0].add_child(4);
    
    println!("Sum: {}", root.sum());  // 1 + 2 + 3 + 4 = 10
}
```

`Box<T>` is a heap-allocated owned pointer. Clear ownership: parents own children.

---

## The Limitation: No Parent References

With ownership chains, children can't reference their parent:

```rust
struct TreeNode {
    value: i32,
    parent: ???,  // What type goes here?
    children: Vec<Box<TreeNode>>,
}
```

If the parent owns the child, the child can't also own (or even borrow) the parent without creating cycles or borrow conflicts.

---

## Option 2: Arena Allocation with Indices

Instead of pointers, use indices into a shared arena:

```rust
struct NodeId(usize);

struct Node {
    value: i32,
    parent: Option<NodeId>,
    children: Vec<NodeId>,
}

struct Tree {
    nodes: Vec<Node>,
}

impl Tree {
    fn new(root_value: i32) -> Self {
        Tree {
            nodes: vec![Node { 
                value: root_value, 
                parent: None, 
                children: vec![] 
            }],
        }
    }
    
    fn root(&self) -> NodeId {
        NodeId(0)
    }
    
    fn add_child(&mut self, parent: NodeId, value: i32) -> NodeId {
        let new_id = NodeId(self.nodes.len());
        self.nodes.push(Node {
            value,
            parent: Some(parent),
            children: vec![],
        });
        self.nodes[parent.0].children.push(new_id);
        new_id
    }
    
    fn get(&self, id: NodeId) -> &Node {
        &self.nodes[id.0]
    }
}

fn main() {
    let mut tree = Tree::new(1);
    let root = tree.root();
    let child1 = tree.add_child(root, 2);
    let child2 = tree.add_child(root, 3);
    let _grandchild = tree.add_child(child1, 4);
    
    println!("Root value: {}", tree.get(root).value);
    println!("Child1 parent: {:?}", tree.get(child1).parent);
    println!("Root children: {:?}", tree.get(root).children);
}
```

---

## Why Arena + Indices Works

- **One owner**: The `Tree` struct owns all nodes
- **References via indices**: `NodeId` is just a number - it can be copied freely
- **Parent references**: Now possible! The index is just data, not a borrow
- **Familiar pattern**: This is how ECS architectures work

Trade-off: You need the arena to access any node. But that's often fine.

---

## Option 3: Interior Mutability (Use Sparingly)

Sometimes you need shared ownership with mutation. `Rc<RefCell<T>>` provides this:

```rust
use std::rc::Rc;
use std::cell::RefCell;

struct Node {
    value: i32,
    children: Vec<Rc<RefCell<Node>>>,
}

fn main() {
    let root = Rc::new(RefCell::new(Node { 
        value: 1, 
        children: vec![] 
    }));
    
    let child = Rc::new(RefCell::new(Node {
        value: 2,
        children: vec![],
    }));
    
    // Multiple owners (Rc), runtime borrow checking (RefCell)
    root.borrow_mut().children.push(Rc::clone(&child));
    
    println!("Root has {} children", root.borrow().children.len());
}
```

---

## Why Rc<RefCell<T>> is a Code Smell

This works, but you've traded compile-time safety for runtime checks:

```rust
use std::rc::Rc;
use std::cell::RefCell;

fn main() {
    let data = Rc::new(RefCell::new(vec![1, 2, 3]));
    
    let borrow1 = data.borrow();
    // let borrow2 = data.borrow_mut();  // PANIC at runtime!
    //                                   // "already borrowed: BorrowMutError"
    
    println!("{:?}", borrow1);
}
```

The borrow rules still apply - but violations are panics instead of compile errors.

Use `Rc<RefCell<T>>` when you genuinely need shared mutable state. But first, ask: can I redesign to avoid this?

---

## The Entity-Component Pattern

Games often use this pattern (we'll see more in Part 7):

```rust
// Components are just data
struct Position { x: f32, y: f32 }
struct Velocity { dx: f32, dy: f32 }
struct Health { current: i32, max: i32 }

// Entities are IDs
#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct EntityId(u32);

// The world owns all component storage
use std::collections::HashMap;

struct World {
    next_id: u32,
    positions: HashMap<EntityId, Position>,
    velocities: HashMap<EntityId, Velocity>,
    healths: HashMap<EntityId, Health>,
}

impl World {
    fn new() -> Self {
        World { 
            next_id: 0,
            positions: HashMap::new(), 
            velocities: HashMap::new(),
            healths: HashMap::new(),
        }
    }
    
    fn spawn(&mut self) -> EntityId {
        let id = EntityId(self.next_id);
        self.next_id += 1;
        id
    }
}

fn main() {
    let mut world = World::new();
    
    let player = world.spawn();
    world.positions.insert(player, Position { x: 0.0, y: 0.0 });
    world.velocities.insert(player, Velocity { dx: 1.0, dy: 0.0 });
    world.healths.insert(player, Health { current: 100, max: 100 });
    
    let enemy = world.spawn();
    world.positions.insert(enemy, Position { x: 10.0, y: 5.0 });
    world.healths.insert(enemy, Health { current: 50, max: 50 });
    // Enemy has no velocity - it doesn't move
    
    println!("Player at ({}, {})", 
             world.positions[&player].x, 
             world.positions[&player].y);
}
```

---

## Why Entity-Component Works Well

- **Clear ownership**: The `World` owns all data
- **Composition over inheritance**: Entities have whatever components they need
- **Cache-friendly**: Components stored contiguously (with the right data structures)
- **Easy to extend**: Add new component types without changing existing code

This isn't just a workaround - it's often a better design than object hierarchies.

---

## The Design Lesson

When the borrow checker pushes back, ask:

1. **Who really owns this data?** Make it explicit.
2. **Can I use indices instead of references?** Arena patterns work well.
3. **Do I need shared mutable state?** Often you don't.
4. **Is my OOP design actually the best fit?** Entity-Component might be cleaner.

The borrow checker isn't fighting you - it's asking you to clarify your design. Often, the clearer design is also the better one.
