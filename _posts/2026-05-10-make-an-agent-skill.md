---
title: Make an Agent Skill
date: 2026-05-10 22:00:00 +0700
categories: [Techtalk]
tags: [ai]
---

TL;DR: To make an Agent Skill, you start a conversation with AI, do exactly what you do in daily work, do ask and answer with the AI, and at the end, summarize everything into a markdown file (with scripting if needed) and use it as the Agent Skill. The accuracy of the skill is very high, because you are just cloning what you have done before, and the AI is just helping you to write it down in a more structured way.

After trying some ways to make Agent Skill for both work and personal projects, I found a simple way to do it with high accuracy: just clone what you have done to become the Agent Skill, then invoke it when you need it again.

## The problem

I often use Agent Skill as a function with a high probability of accuracy, which means the output may contain incorrect things but not too many. So the goal when I make a new Agent Skill is to make it as accurate as possible, not 100% perfect. But even with that goal, the work is not easy. There are a few ways I tried before, but they all have some problems.

1. Clone a high-hype Agent Skill from the internet and modify it to fit my needs. I tried this for months, but almost every time, in the final version of the skill, the only remaining thing is the core concept of the skill; the content is totally different because I modified all of it to match my needs. There are a few examples, [Matt Pocock](https://github.com/mattpocock/skills) and [Addy Osmani](https://github.com/addyosmani/agent-skills). They are good, but I feel like they are disconnected from my daily routines, so I need to cook them to fit my needs.

2. Create a new Agent Skill from scratch. This is the most difficult way, because designing an Agent Skill is like starting to design a complex system plan, then implementing it, testing it, and improving it. It takes a long, long time to finish a skill, many mistakes may happen, and to be honest, I'm lazy to do it ;D

3. *Removed this one, because I don't want to share it :D*

I chose the second way because at the end of the day I have to make everything in my own way, and modifying something is harder than creating your own thing. The most difficult part of the second way is the egg-and-chicken problem: I don't want to write everything by myself, so I want to use AI to write the skill for me, but to make it happen I need to feed enough context to the AI. But to feed enough context, I have to write information down. And if everything is written down, I can just use it as the Agent Skill without the need to make it into a skill. Fakkkk, I don't want to do it that way.

## The Aha moment

In the toilet (what a famous place for many people to have their Aha moment :D), I suddenly thought about how I had guided some junior developers before. I did the task as a sample, they watched how I did it, then tried to do it by themselves, aka hands-on learning. If we imagine the LLM as a mid-level engineer, they know everything, but they don't know how to do it, so they need to watch how I do it, record everything in the conversation between us, note it down as guidance for them, and we, the humans, call it by the name "Agent Skill".

So I have designed a set of Agent Skills below in that way:

```bash
.agents/skills/feature-readme:
total 32
drwxr-xr-x   5 <USERNAME>  staff   160B May 11 08:31 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    15K May 11 08:31 SKILL.md
drwxr-xr-x   4 <USERNAME>  staff   128B May 11 08:31 references
drwxr-xr-x   3 <USERNAME>  staff    96B May  8 11:32 scripts

.agents/skills/feature-testgencase:
total 40
drwxr-xr-x   6 <USERNAME>  staff   192B May 11 08:31 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    17K May 11 08:31 SKILL.md
drwxr-xr-x   4 <USERNAME>  staff   128B May 11 08:31 docs
drwxr-xr-x  17 <USERNAME>  staff   544B May 11 08:31 references
drwxr-xr-x   3 <USERNAME>  staff    96B May  8 11:32 scripts

.agents/skills/feature-testgentask:
total 48
drwxr-xr-x   6 <USERNAME>  staff   192B May 11 08:31 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    21K May 11 08:31 SKILL.md
drwxr-xr-x   4 <USERNAME>  staff   128B May 11 08:31 docs
drwxr-xr-x  23 <USERNAME>  staff   736B May 11 08:31 references
drwxr-xr-x   3 <USERNAME>  staff    96B May  8 11:32 scripts

.agents/skills/feature-testimpl:
total 32
drwxr-xr-x   6 <USERNAME>  staff   192B May 11 08:31 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    13K May 11 08:31 SKILL.md
drwxr-xr-x   4 <USERNAME>  staff   128B May 11 08:31 docs
drwxr-xr-x  21 <USERNAME>  staff   672B May 11 08:31 references
drwxr-xr-x   3 <USERNAME>  staff    96B May  8 11:32 scripts

.agents/skills/feature-testmock:
total 32
drwxr-xr-x   6 <USERNAME>  staff   192B May 11 08:31 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    13K May 11 08:31 SKILL.md
drwxr-xr-x   3 <USERNAME>  staff    96B May 11 08:31 docs
drwxr-xr-x  12 <USERNAME>  staff   384B May 11 08:31 references
drwxr-xr-x   3 <USERNAME>  staff    96B May  7 10:43 scripts

.agents/skills/feature-testverify:
total 48
drwxr-xr-x   4 <USERNAME>  staff   128B May  7 10:43 .
drwxr-xr-x@ 22 <USERNAME>  staff   704B May  7 10:43 ..
-rw-r--r--   1 <USERNAME>  staff    24K May  7 10:43 SKILL.md
drwxr-xr-x   3 <USERNAME>  staff    96B May  7 10:43 scripts
```

These are what I did, step by step:

1. I initialize the conversation with the goal of the agent skill, and ask the LLM to scan some files I already know the LLM must read. This is the first batch of context I feed to the LLM, and I ask them to summarize it, so that I can make sure they know the ultimate goal of the skill and have the basic knowledge to do it.

2. I feed one example of the way I did it in the happy path, and ask the LLM to comment on my way by following these points:

- What did I miss?
- What is partially wrong?
- What is completely wrong?
- *Ask more questions if you want to make it more accurate*

After answering these questions, I ask the LLM to summarize again with the new knowledge they have, including the happy path and their own answers.

3. This is the funniest part: in the project, I'm just a contributor, so I don't know everything, but in my area, I definitely know what the edge cases, the gotchas, the `mo**** fu****` cases, and so on are. I will ask the LLM about them, when these things happen, how we handle them, and ask them to summarize again with the new knowledge.

The final step is to ask the LLM to write the Agent Skill for me. I do a review, and I barely need to modify it, just a few things here and there, and the skill is ready to use.

There is an example of the skill I made this way: the `feature-testgencase` skill that helps me generate test cases for a feature, with the input being the existing code and existing test cases from the Test Engineer.

```bash
.agents/skills/feature-testgencase
├── SKILL.md
├── docs
│   ├── flowchart.md
│   └── orchestration.md
├── references
│   ├── ANALYTICS.md
│   ├── EXPLORATION.md
│   ├── HANDOFF.md
│   ├── IMPROVE.md
│   ├── INVENTORY.md
│   ├── ORCHESTRATION.md
│   ├── PAYWALL.md
│   ├── PREFLIGHT.md
│   ├── REPORT.md
│   ├── SELF_EVOLVE.md
│   ├── UI_ASSERTIONS.md
│   ├── VALIDATION.md
│   ├── VERIFY.md
│   ├── WRITING.md
│   └── feature-memory
│       ├── _TEMPLATE.md
│       └── <feature-specific-memory>.md
└── scripts
    └── validation.sh
```

The initial output is just one file, `SKILL.md`, and the validation script. But the file is too big, so I had to ask the LLM to split it into multiple files, and make a few modifications to make it more accurate and enhance the skill operation. Then the final version is what you see above.

Note: I cannot share more details about the content of the skill, because it contains some confidential information, but I hope you can get the idea of how I make an Agent Skill with high accuracy by just cloning what I have done before.