# Simplicity First

---

## The Principle

Build the simplest thing that solves the problem. Do not design for a future that has not arrived.

Over-engineering is not caution — it is waste. Abstractions that are not needed today add complexity, increase cognitive load, and slow the team down without delivering any value. The cost is immediate. The benefit is hypothetical.

---

## What Over-Engineering Looks Like

- Adding a protocol for a class that only has one implementation and no test requirement
- Creating a coordinator for a flow with a single screen
- Building a generic utility to handle two slightly different cases
- Introducing a layer (use cases, interactors, managers) because it feels like the right architecture pattern, not because the problem demands it
- Designing for multi-tenancy, configurability, or extensibility before there is a second use case

The signal is always the same: the code is more complex than the feature it serves.

---

## The Rule

> Add complexity only when the problem forces you to.

One concrete implementation is better than a premature abstraction. Three lines of duplicated code is better than a helper that exists for two call sites. A simple function is better than a class hierarchy built for flexibility you do not need.

When a second use case arrives, refactor then. The code will be easier to generalise from two real examples than from one imagined future.

---

## How to Apply It

Before adding a new layer, abstraction, or pattern, ask:

1. **Is there more than one consumer today?** If not, do not abstract yet.
2. **Does this make testing easier?** If it only adds indirection without enabling a mock, it is not justified.
3. **Would a new engineer understand this in five minutes?** If not, the complexity needs a reason.
4. **Am I solving a real problem or a hypothetical one?** Hypothetical problems do not justify real complexity.

---

## The Balance

Simplicity does not mean shortcuts. It does not mean skipping protocols where they enable testability, or skipping the repository pattern because it feels like extra files. The architecture defined in this playbook exists because those patterns solve real problems the team has already hit.

The principle is not "write less code." It is "do not add structure the problem does not require."

When in doubt, start simple and let the code tell you when it needs more structure.
