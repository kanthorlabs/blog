---
title: Everybody will become an Engineering Manager soon.
date: 2026-06-31 22:30:00 +0700
mermaid: true
categories: [Techtalk]
tags: [ai]
---

**TL;DR:** At the time this blog post was written, LLMs were super powerful: they could do whatever you asked them to, or they could discover what you didn't ask for too. The way we are working in programming has fundamentally changed: we do not program in a professional environment anymore, because it's too slow to get things done. Instead, now I observe the pattern that everyone is struggling to manage their AI agents, exactly like how an engineer manages a team of human developers.

## The Engineering Manager vision

I have always said that every engineer will eventually become an Engineering Manager, not only in the age of AI but also a long time ago. It's because to scale your impact, you need to manage not just your own work but the work of others, and in the age of AI, those "others" also count AI agents in your list.

So the struggle to manage work does not just appear suddenly; you will face it once you start managing a small to medium team. Every day, you jump from meeting to meeting to make sure your team goes in the correct direction, your team receives correct requirements and pushes back on significant nonsense change requests :D You are the hero, a super-powered engineer. But it's just a side of the story. The real challenge is that your team may need your input for code reviewing, architecting, hands-on guidance, and decision making, and a ton of engineering work is waiting for you when you leave the meeting room. Did you see a PR with a thousand lines of changes recently? You feel that pain, huh?

Now, let's scale that kind of workload to 10x, and boom, you are facing the same challenge with AI Agents management. It's worth it, because no matter how powerful the AI agents are, they still need human oversight, coordination, and decision-making to ensure the work aligns with the overall goals and quality standards.

**LLM vs Human:**

Opus can do a real engineer's work because it can remember the branch content. If you ask for something, then later you ask for another thing in the same session, it remembers and delivers work in an appropriate order.

GPT-family models, on the other hand, put significant focus on the recent task you have provided in the current session; then you will feel they're stupid, but they are not. Tibo's tweet already mentioned it; he said GPT models and Codex have been developed with the use of sub-agents: one is orchestrating the overall workflow while the other handles specific tasks. That's why they need the model to focus on a single task intensively.

An Engineering Manager is the one who needs to know what the pros and cons of different folks are so that they can assign tasks effectively, leverage individual strengths, and provide appropriate guidance and support where needed. Like humans, we need to onboard our agents, give them enough context and guidance to perform their tasks.

Same challenge, different scale. Same pain, different actors.

## The loss of reviewing

Back to the Engineering Manager perspective, remember the thousands of lines of change in a PR? Writing down LGTM and moving on is a quick escape plan, but it will get back to you and bite you later on on-call duty. Or reviewing a technical proposal at the end of the day after 4 meetings consecutively? **YOU WILL REVIEW IT CAREFULLY, WON'T YOU?**

In my case, I do professional work in the daytime, and get back to my own experiments and personal projects at night. By that time, my brain barely has `brain credits` left to carefully review anything, and mistakes are inevitable. Last month, due to work pressure at the company, I often ended up saying YES to everything agents suggested to me, and you can guess what is happening right now in the codebase.

But fortunately, weak times create strong men; I found a way to reduce the bloat of what I need to review in AI agents' work. It's an old friend of ours: the sequence diagram. Visualizing makes everything clearer and easier to follow; then you don't need to jump into a wall of text and get drowned in it. The method is super simple to follow:

- If you develop a new feature, start by drawing an overview sequence diagram, review it, then make necessary modifications until you can approve it. Then start splitting the work into smaller tasks and create detailed sequence diagrams for each task. Now the validation method is simple: you assert every step in the sequence diagram against the actual implementation, ensuring that the work aligns with the intended design and requirements.
- If you modify an existing feature, draw a sequence diagram highlighting the changes you plan to make. Review, approve, then assert every change step against the actual implementation.

One more aspect of reviewing is that I now allow agents to do the work, but everything, not only code but also documentation, design decisions, and other artifacts produced by the agents, must go through a guardrail script. Sounds familiar? It's similar to having a CI check for your team's work before it gets into main, huh? Those two things work together: the sequence diagram reduces what I must read; the guardrail removes what I don't need to read at all. That's the part which saves me at night, because a script never runs out of `brain credits`. But keep in mind a script only checks what you tell it to check: structure, conventions, required sections, and links back to the steps in your sequence diagram. It cannot tell you a design decision is correct, so my judgement is still required, just on a much smaller surface.

## The drift of Claude Code

Opus started talking nonsense (aka like sh!t) recently; I even had to add a hook to catch the response and ask GPT-5.6-luna to rephrase it for me. Someone thinks it's an annoyance, but for me, it's P0 of my workflow because now I cannot understand what Opus is trying to propose; then I need to put more effort into reviewing and validating its output, which slows down my overall productivity significantly. Overall, Anthropic has the best model family, a good harness, but my interest in using it has waned due to the recent drift in Claude Code's responses.

A more serious question is that I optimize my workflow around Claude Code and Anthropic's models; that vendor lock-in could become an incident once they make minor changes to their APIs or model behaviors, or even worse, if their classification model makes wrong predictions while executing sensitive tasks.

Furthermore, nowadays coding is cheap and my experiment with an agentic system by using the OpenCode harness is mature enough to build my own agentic system. Nowadays I have lots of agent setups, tooling and infrastructure in place to support my custom agentic system, and it will be better for me to consolidate my workflow around my own system rather than relying heavily on third-party models and harnesses. With a full-control harness, now I can build a reliable agentic system based on unreliable third-party models and still maintain high productivity and quality.
