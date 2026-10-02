# Metro Mate — GCD → Swift Concurrency

<p align="left">
  <a href="https://www.3daysofswiftconcurrency.com/">
    <img
      src="readme-images/README-Logo-h512.png"
      width="160"
      alt="3 Days of Swift Concurrency"
    >
  </a>
</p>

> A real iOS application.  
> A real legacy GCD codebase.  
> One AI-assisted Swift Concurrency migration you can inspect, compare and reproduce yourself.

This repository is a practical demonstration of migrating an existing iOS application from **Grand Central Dispatch (GCD)** to **Swift Concurrency** using the **Cooperative Feature Architecture (CFA) Toolkit**.

It is intentionally kept as a fork of the original Metro Mate project.

That means you don't have to take our word for what the application looked like before the migration.

You can see it.

You can run it.

You can compare it.

And, most importantly, **you can try migrating it yourself.**

---

## 👀 Start Here: See the Migration

This repository deliberately keeps the original and migrated applications on separate Git branches.

```text
main
│
└── Original Metro Mate
    └── GCD implementation


migration/cfa-toolkit-swift-concurrency
│
└── CFA Toolkit migration
    └── Swift Concurrency implementation
```

### Original Application

The `main` branch preserves the starting point.

### Migrated Application

The completed migration lives on:

`migration/cfa-toolkit-swift-concurrency`

### 🔀 See Every Change

GitHub can compare the two branches for you:

**[View the complete GCD → Swift Concurrency migration](https://github.com/3DaysOfSwift/metro-mate-ios/compare/main...migration/cfa-toolkit-swift-concurrency)**

This is one of the most useful parts of this repository.

You're not looking at a simplified tutorial example.

You're looking at the changes made to a real application.

---

# What Is CFA?

**CFA stands for Cooperative Feature Architecture.**

CFA is an architecture for building modern iOS applications with SwiftUI, Swift Concurrency and AI coding agents.

Think of architecture as deciding **where everything belongs**.

A house has rooms.

A school has classrooms.

A supermarket has aisles.

Without that structure, finding anything would become difficult.

Software is the same.

As an application grows, thousands of lines of code need sensible places to live.

**CFA provides those places.**

It gives the developer and their AI coding agent a shared set of rules for questions such as:

- Where should this code go?
- Who owns this state?
- Which object is responsible for this feature?
- Should this work happen on the Main Actor?
- Should an actor own this concurrent work?
- How should two features communicate?
- Where should a dependency be created?
- How can somebody else understand this code six months from now?

The goal is simple:

> **Make modern iOS applications easier to write, read, change and maintain.**

CFA isn't only for creating new applications.

The toolkit also contains skills for working with existing codebases, reviewing architecture, tidying code and migrating legacy concurrency code.

**[View the CFA Toolkit on GitHub](https://github.com/3DaysOfSwift/cooperative-feature-architecture)**

---

# What Is the CFA Toolkit?

CFA isn't something you import into your iOS application.

There is no:

```swift
import CFA
```

Instead, **CFA is installed into your AI coding environment.**

The toolkit gives your coding agent detailed instructions describing how to perform particular software-engineering jobs.

The CFA Toolkit includes AI skills for jobs such as:

| Skill | What It Does |
|---|---|
| **CFA App Creation** | Builds a new application using CFA |
| **CFA Architecture Adoption** | Brings CFA structure to an existing application |
| **Swift Concurrency Migration** | Migrates legacy concurrency code |
| **CFA Architecture Review** | Reviews an application's architecture |
| **CFA Codebase Tidy** | Improves the organisation of an existing codebase |

It also includes the **Xcode Project Dashboard**.

For this repository, the important skill is:

## Swift Concurrency Migration

This skill teaches the coding agent how to investigate legacy concurrency **before changing it**.

That's important.

Migrating GCD isn't simply:

```text
DispatchQueue → Task
```

The old code may be using queues to guarantee:

- ordering
- mutual exclusion
- thread safety
- cancellation
- state protection
- callback ordering
- where particular work executes

Those behaviours have to be understood **before** the old concurrency code is replaced.

That's what the CFA migration skill is designed to help with.

---

# 🧰 Install the CFA Toolkit

CFA is a toolkit for AI-assisted iOS development.

It contains two important parts:

1. **The CFA development tool**
2. **A set of CFA AI coding skills**

The tool provides additional CFA development functionality, while the AI skills teach your coding agent how to perform specific development tasks using CFA.

CFA is **not** a framework that gets compiled into your iOS application.

You do not write:

```swift
import CFA
```

Instead, CFA is installed into your **AI coding environment**.

Once installed, your AI coding agent can use CFA while it works with your Xcode projects.

---

## What Are the CFA AI Skills?

Each skill teaches your AI coding agent how to perform a particular development job.

The toolkit currently includes skills for:

| CFA Skill | What It Does |
|---|---|
| **CFA App Creation** | Creates a new iOS application using CFA |
| **CFA Architecture Adoption** | Introduces CFA into an existing application |
| **Swift Concurrency Migration** | Migrates legacy concurrency code to Swift Concurrency |
| **CFA Architecture Review** | Reviews the structure of an application |
| **CFA Codebase Tidy** | Improves the organisation of an existing CFA codebase |

This means you can give your AI coding agent an instruction such as:

```text
Use the CFA App Creation skill to create a new SwiftUI app.
```

Or, as demonstrated by this repository:

```text
Use the Swift Concurrency Migration skill to migrate this
GCD application to Swift Concurrency.
```

The skill contains the detailed engineering instructions the AI needs to carry out that job.

---

# 📦 Step 1 — Download CFA

Download the latest CFA release:

**[Download the latest CFA Toolkit](https://github.com/3DaysOfSwift/cooperative-feature-architecture/releases)**

Download the CFA plugin ZIP from the latest release and extract it.

> Use the CFA release package rather than GitHub's automatically generated "Source code" ZIP.

You now have the CFA Toolkit on your Mac.

The next step is to make CFA available to your AI coding agent.

---

# ⚙️ Step 2 — Install CFA

There are currently two installation modes.

**Choose the one that matches your AI coding environment.**

---

## Using OpenAI Codex?

Run:

```zsh
node scripts/install.mjs
```

This installs the **complete CFA plugin for Codex** and activates the CFA AI coding skills.

Use this option if Codex is your coding agent.

---

## Using Another AI Coding Agent?

If your AI coding agent supports agent skills, run:

```zsh
node scripts/install.mjs --mode skills
```

This installs CFA's AI coding skills into:

```text
~/.agents/skills
```

Your coding agent must support discovering skills from that location.

Use this option for compatible AI coding agents that do not use the Codex plugin system.

---

## Which Command Should I Use?

It's simple:

```text
Using Codex?
    │
    └── node scripts/install.mjs


Using another compatible AI coding agent?
    │
    └── node scripts/install.mjs --mode skills
```

Both approaches give your AI access to the **CFA coding skills**.

The Codex installation additionally installs CFA through the Codex plugin system.

For the complete installation guide, requirements and troubleshooting:

**[Read the CFA Installation Guide](https://github.com/3DaysOfSwift/cooperative-feature-architecture/blob/main/docs/INSTALLATION.md)**

---

# 🚀 CFA Is Installed. What Now?

Now comes the useful part.

You can give your AI coding agent a job and tell it which CFA skill to use.

You don't need to explain the entire CFA architecture yourself.

The skill does that.

---

## Create Your First CFA App

For example, ask your AI coding agent:

```text
Use the CFA App Creation skill to create a new SwiftUI iPhone app.

Call the app MyNotes.

The user should be able to create a note, save it and see their
saved notes.

Keep the first version simple.

Use CFA to structure the application.

Build the project and run its tests when your tooling allows it.
```

Your AI coding agent now has two things:

```text
Your idea
    +
CFA's engineering instructions
    │
    ▼
A structured iOS application
```

You describe **what you want to build**.

CFA helps your AI coding agent understand **how the application should be structured**.

---

# 🧠 What Does CFA Actually Do?

Think of CFA as a shared architectural language between you and your AI coding agent.

As an application grows, somebody needs to make decisions such as:

- Where should this code live?
- Who owns this state?
- Where does business logic belong?
- How should features communicate?
- Where should dependencies be created?
- Which work belongs on `@MainActor`?
- Should an actor own this concurrent state?
- How do we stop Views becoming responsible for everything?
- How do we make this code understandable six months from now?

CFA gives the developer and the AI a common structure for answering those questions.

The goal is straightforward:

> **Make modern iOS applications easier to write, read, change and maintain.**

---

# 🛠️ CFA Isn't Just for New Apps

You can use CFA throughout the life of an application.

## Create a New Application

Ask your AI:

```text
Use the CFA App Creation skill to create this application using CFA.
```

---

## Introduce CFA Into an Existing Application

Already have an app?

Ask:

```text
Use the CFA Architecture Adoption skill to introduce CFA into
this existing application.

Preserve the existing behaviour and migrate the architecture
progressively.
```

---

## Review Your Architecture

You can ask CFA to inspect an application without immediately changing it:

```text
Use the CFA Architecture Review skill to review this application.

Do not modify the source code.

Explain where responsibilities, state ownership, dependencies
or concurrency boundaries could be clearer.
```

---

## Tidy an Existing CFA Application

Ask:

```text
Use the CFA Codebase Tidy skill to review and tidy this CFA project.

Preserve the existing behaviour while improving its organisation.
```

---

# 🔄 Or Migrate a Legacy GCD Application

This is the CFA capability demonstrated by **Metro Mate**.

CFA contains a dedicated **Swift Concurrency Migration** skill.

The purpose isn't simply to search for:

```swift
DispatchQueue
```

and replace it with:

```swift
Task
```

Real applications are more complicated than that.

Existing GCD code may be providing important guarantees involving:

- execution ordering
- protected mutable state
- serial execution
- cancellation
- callback delivery
- thread safety
- error handling
- communication between components

Those guarantees need to be understood before the concurrency implementation is changed.

The CFA migration skill gives the AI a structured process for approaching that work.

---

# 🧪 Try the Metro Mate Migration Yourself

This repository lets you perform the same experiment.

Clone Metro Mate:

```zsh
git clone https://github.com/3DaysOfSwift/metro-mate-ios.git
cd metro-mate-ios
```

Make sure you're starting with the original GCD application:

```zsh
git switch main
```

Create your own migration branch:

```zsh
git switch -c my-swift-concurrency-migration
```

Open the project in your AI coding environment.

Then give your AI coding agent the job:

```text
Use the CFA Toolkit's Swift Concurrency Migration skill.

Migrate this GCD iOS application to Swift Concurrency.

Understand and preserve the behavioural guarantees provided by
the existing concurrency implementation before replacing it.
```

Then let your AI coding agent investigate the application and begin the migration.

---

# 🔀 Compare Your Migration With Ours

When you've finished, you can compare your solution with the migration performed for this repository.

Our migrated application lives on:

```text
migration/cfa-toolkit-swift-concurrency
```

GitHub can show you the entire migration:

**[View the complete GCD → Swift Concurrency migration](https://github.com/3DaysOfSwift/metro-mate-ios/compare/main...migration/cfa-toolkit-swift-concurrency)**

Now you can ask:

- Did our AI agents identify the same concurrency problems?
- Did we protect state in the same way?
- Did we introduce actors in the same places?
- Did responsibilities move between components?
- Did our migrations make different architectural decisions?
- Did we preserve the same behaviour?
- Which implementation is easier to understand?

You aren't reading a theoretical migration tutorial.

You're looking at a real application, starting from the same source code, and you're free to perform the experiment yourself.

---

# 🌱 Start Using CFA

You don't need a legacy application to experiment with CFA.

You can start with something tiny.

Install CFA and tell your AI coding agent:

```text
Use the CFA App Creation skill.

Create a simple SwiftUI iPhone app that lets me record things
I need to do today and mark them as completed.

Use CFA to structure the application.

Keep the first version small and easy to understand.
```

Then open the project and explore what your AI created.

Look at where state lives.

Look at where business behaviour lives.

Look at how the Views communicate with the rest of the application.

Then change something.

Add a feature.

Ask CFA to review it.

That's one of the easiest ways to understand what an architecture is actually giving you:

**build something with it.**
---

# 🚀 Try the Metro Mate Migration Yourself

This is where this repository becomes particularly useful.

You don't have to simply read about our migration.

**You can perform the same experiment yourself.**

Clone Metro Mate:

```zsh
git clone https://github.com/3DaysOfSwift/metro-mate-ios.git
cd metro-mate-ios
```

Make sure you're starting from the original application:

```zsh
git switch main
```

Create your own migration branch:

```zsh
git switch -c my-swift-concurrency-migration
```

Now open the project using your AI coding environment.

Make sure CFA is installed.

Then give your coding agent a simple instruction:

> **Using the CFA Toolkit, migrate this GCD iOS app to use Swift Concurrency.**

That's where the experiment begins.

The migration skill should first investigate how the existing application works.

It can then progressively migrate the application while attempting to preserve the behavioural guarantees provided by the existing implementation.

---

# 🧪 Compare Your Migration With Ours

This is one of the reasons we've kept the migration on its own Git branch.

You started with the **same application**.

You started with the **same source code**.

You're using the **same CFA Toolkit**.

But your AI coding session may make different decisions.

When you're finished, compare your implementation with ours:

```text
migration/cfa-toolkit-swift-concurrency
```

You can investigate questions such as:

- Did we identify the same concurrency problems?
- Did we introduce actors in the same places?
- Did we preserve the same behaviours?
- Did our coding agents make different architectural decisions?
- Which responsibilities moved?
- How did state ownership change?
- How did the application's concurrency model change?
- Is the resulting application easier to understand?

Now you're not simply reading about Swift Concurrency.

**You're investigating a real migration.**

---

# Why Keep `main` Unmigrated?

Normally, after completing a feature branch, we'd merge it into `main`.

We're deliberately **not doing that here**.

This repository is an educational resource.

We want:

```text
main
     ↓
BEFORE
```

and:

```text
migration/cfa-toolkit-swift-concurrency
     ↓
AFTER
```

to remain available.

That means GitHub itself becomes part of the teaching material.

The Git history records the journey.

The migration branch contains the result.

And GitHub's comparison tools show exactly what changed.

### Compare them now:

**[Original GCD application → CFA Swift Concurrency migration](https://github.com/3DaysOfSwift/metro-mate-ios/compare/main...migration/cfa-toolkit-swift-concurrency)**

---

# About 3 Days of Swift Concurrency

<p align="left">
  <a href="https://www.3daysofswiftconcurrency.com/">
    <img
      src="readme-images/README-Logo-h512.png"
      width="160"
      alt="3 Days of Swift Concurrency"
    >
  </a>
</p>

**CFA is created and published by 3 Days of Swift Concurrency.**
 <a href="https://www.3daysofswiftconcurrency.com/">3DaysOfSwiftConcurrency.com</a>
 
We build practical resources for iOS developers learning and applying modern Swift Concurrency.

CFA grew from a simple idea:

> **If developers are increasingly building software alongside AI, then the developer and the AI should share a clear architectural language.**

Instead of repeatedly explaining where state should live, how features should communicate, or which component owns a responsibility, CFA gives the developer and AI a common structure.

It's designed to be a useful all-round architecture for modern iOS development.

You can use CFA to help:

- build a new application
- organise an existing application
- make responsibilities clearer
- make code easier to read
- make code easier to maintain
- review an application's architecture
- tidy an existing codebase
- introduce modern Swift Concurrency
- migrate legacy GCD code to Swift Concurrency

CFA is not intended to hide Swift or Swift Concurrency from you.

It's a structure for helping humans and AI work with those technologies more consistently.

### Learn More

**[3 Days of Swift Concurrency](https://www.3daysofswiftconcurrency.com/)**

**[Download and Install the CFA Toolkit](https://github.com/3DaysOfSwift/cooperative-feature-architecture)**

**[CFA Releases](https://github.com/3DaysOfSwift/cooperative-feature-architecture/releases)**

---

# About the Original Metro Mate Project

Metro Mate was created by its original author independently of this migration experiment.

This repository remains a GitHub fork so that the provenance of the original project remains visible.

The CFA migration is maintained separately from the original project and should not be mistaken for work performed by or endorsed by the original author.

---

## The Whole Experiment in One Picture

```text
Original Metro Mate
        │
        │
        ▼
   GCD Codebase
        │
        │
        │  Install CFA into your AI coding environment
        │
        ▼
┌──────────────────────────────┐
│      CFA Migration Skill     │
│                              │
│ Understand the old code      │
│ Understand responsibilities  │
│ Understand concurrency       │
│ Preserve behaviour           │
│ Introduce modern structure   │
│ Migrate to Swift Concurrency │
└──────────────────────────────┘
        │
        │
        ▼
Swift Concurrency Version
        │
        ▼
Inspect it
Run it
Compare it
Learn from it
Try it yourself
```

**The original application is the lesson.**

**The migration is the experiment.**

**The Git diff is the evidence.**

And the entire thing is here for you to explore.