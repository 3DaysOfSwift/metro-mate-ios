# Metro Mate — GCD → Swift Concurrency

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

# 🧒 Installing CFA — The Simple Version

If you've never installed an AI coding skill before, don't worry.

The basic idea is:

```text
Download CFA
     ↓
Install CFA into your coding agent
     ↓
Open your Xcode project
     ↓
Tell the agent to use a CFA skill
```

That's it.

## Step 1 — Download CFA

Go to the CFA releases page:

**[Download the latest CFA release](https://github.com/3DaysOfSwift/cooperative-feature-architecture/releases)**

Download the plugin ZIP from the latest release.

Use the **plugin ZIP**, rather than GitHub's automatically generated source-code ZIP, when installing the plugin.

---

## Step 2 — Extract It

Double-click the ZIP file.

You'll get a folder containing CFA.

Keep that folder intact.

---

## Step 3 — Install CFA

Open Terminal inside the extracted CFA folder.

Run:

```zsh
node scripts/install.mjs
```

On macOS you can alternatively open:

```text
Install.command
```

The installer installs CFA and makes its skills available to your supported AI coding environment.

### Using Another Compatible AI Coding Agent?

CFA also provides a skills-only installation:

```zsh
node scripts/install.mjs --mode skills
```

This installs the skill folders under:

```text
~/.agents/skills
```

Your AI coding agent must support discovering skills from that location.

For complete installation instructions and troubleshooting:

**[Read the CFA Installation Documentation](https://github.com/3DaysOfSwift/cooperative-feature-architecture/blob/main/docs/INSTALLATION.md)**

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

<!--
Add the 3 Days of Swift Concurrency logo to this repository.

For example:

readme-images/3-days-of-swift-concurrency.png

Then replace this comment with:

<p align="center">
  <a href="https://www.3daysofswiftconcurrency.com/">
    <img
      src="readme-images/3-days-of-swift-concurrency.png"
      width="160"
      alt="3 Days of Swift Concurrency"
    >
  </a>
</p>
-->

**CFA is created and published by 3 Days of Swift Concurrency.**

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