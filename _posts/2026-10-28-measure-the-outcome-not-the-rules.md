---
title: Measure the outcome, not the rules
date: 2026-10-28 20:00:00 +0700
categories: [Techtalk]
tags: [ai, agents, evaluation]
---

> **Disclaimer:** Claude Code, an AI coding agent, wrote this post from our working session. Tuan Nguyen directed the work but did not write the text. Read it with caution, and check each number and claim against the eval set before you rely on it.
{: .prompt-warning }

**TL;DR**: I cut my `/explain` agent skill from 267 lines to 192 lines. Before the cut, I built an eval of 30 cases that measures what the skill is for, not what the skill says. Over two runs each, the shorter skill scores 0.872 against 0.716 on the main cases, and 0.856 against 0.785 on holdout cases that the editor never saw.

## The skill

I work with a coding agent all day. When a problem is not clear, I invoke a skill called `/explain`. The skill shapes one message: a conclusion first, a numbered timeline that shows where things break, the fix, and exactly one question for me to rule on.

In one day, I had to ask the agent back three times:

1. It offered two fixes inside the frame that I gave it. The real fix was at the source.
2. It proposed a longer denylist of environment variables. It never asked why the process inherited those variables at all. An allowlist was better. It also left a fact "for before the PR", and that fact was wrong.
3. It proposed to remove a column without the current mechanism or the reason. It left a schema fact "for before the PR" too.

The pattern was the same each time: no challenge of the premise, unchecked facts, and predictable questions left unanswered. So I added a `Self-debate` section to the skill. Before it recommends anything, the agent must name the root cause, drop each option that fails the task, rank the rest for this task, attack its own choice, check every fact that the choice depends on now, and answer my next three questions.

The skill grew to 267 lines. Every line of a skill costs context on every invocation, so I wanted it lighter. I did not want to find out a week later that the lighter version made worse decisions.

## First attempt: test the rules

The first eval set that the agent built checked the rules of the skill. Is the conclusion first? Does the timeline have 4 to 8 steps? Is there an em-dash? Is there exactly one question at the end? It had 299 checks per run, and 200 of them were mechanical.

One sample showed the problem. In the denylist case, the model found the real fix: an allowlist that includes `HTTPS_PROXY` and `HOME`, which the plugin code reads and the contract document omits. The answer was correct. It still failed 4 of 30 checks, one of them for a parenthetical aside.

A rule is a means. A refactor can keep every rule check green and still make worse decisions, or break a rule and give a better answer. So I stopped the run and asked a different question: what does success look like when I use `/explain`?

## Define success first

The goal of the skill is one sentence:

> After one message, I make the correct ruling without a follow-up question.

Every measure must answer that sentence:

| Measure | Question it answers |
| --- | --- |
| M1 Right decision | Is the recommendation one of the correct options for this task? |
| M2 True facts | Does every fact that the decision depends on match the files? Is no fact left for later? |
| M3 No follow-up | Does the message answer the questions I need before I rule? |
| M4 Understanding | Can a reader rebuild the problem, what breaks, the fix and the cost from the message alone? |
| M5 Answerable close | Does the message end with exactly one decision that I can answer from the message? |
| M7 Valid alternative | Is each alternative a correct option with a real trade-off? |
| MF Factual answer | Does a one-line question get a short answer without the template? |

M6 is the word count of the message. It does not pass or fail. It breaks ties.

The rule checks stayed, but only as diagnostics. When a score drops, they help find which removed rule caused it.

## What is an alternative?

While I defined M7, I noticed why I ignored most alternatives in practice. The skill asked for an alternative that "beats the recommendation on one aspect". The agent filled that slot with options that did not solve the problem. The worked example in the skill itself did it: a per-order lock as the alternative to a stored idempotency key, but the lock does not stop the double charge.

An alternative is not a wrong answer. It is a correct option with a different trade-off. For one task its pros outweigh its cons, so it is the primary. For another task the same two options swap places. So the skill now says: drop every option that fails the task, rank the rest for this task, and state the condition that makes the alternative the primary.

The eval tests this with a swap pair. Two cases have the same CSV export bug and the same two correct fixes: stream the response, or run an async job that emails a link. With 6 exports per day and no job queue, streaming is the primary. With 900 exports at month end and an existing job queue, the async job is the primary.

## How one run works

Each case is a small fake project: a prompt, a `fixture/` directory with code and documents, and a hidden `key.json`. The key holds the correct recommendations, the invalid options, the root cause, each dependent fact with the file that proves it, the questions I need answered, the valid alternatives, and the decision that is still open.

1. **Generate.** Sonnet at medium effort answers the prompt with the skill appended to its system prompt. It can read the fixture. It never sees the key.

   ```shell
   claude -p --safe-mode --model sonnet --effort medium \
     --tools "Read,Grep,Glob" --permission-prompts none \
     --append-system-prompt-file SKILL.md "<case prompt>"
   ```

2. **Read.** A second call plays me. It sees the case prompt and the message, nothing else. It states the decision it would make, rebuilds the problem, lists its follow-up questions, and answers the closing question.
3. **Grade.** A third call compares the message and the reader notes with the key. It returns pass or fail per measure, with a quoted piece of evidence. It never sees the skill.
4. **Report.** A script sums the cells per measure, per case and in total.

`--safe-mode` keeps my own instructions, installed skills and plugins out of the run. It was not enough on its own: from inside the repository, the model still saw the git status and my email address. Each case now runs in a temporary copy of its fixture, outside any git repository.

## Noise and the bar for "no drop"

A model is not deterministic, so one run proves little. I ran the 267-line skill twice with 3 repeats per case, and once with an empty skill as a control.

| Run | Total | M1 | M2 | M3 | M4 | M5 | M7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Skill, run 1 | 0.737 | 0.83 | 0.76 | 0.62 | 0.81 | 0.67 | 0.73 |
| Skill, run 2 | 0.695 | 0.89 | 0.64 | 0.51 | 0.83 | 0.69 | 0.64 |
| No skill | 0.438 | 0.75 | 0.43 | 0.30 | 0.54 | 0.21 | 0.41 |

The control tells me where the skill earns its lines. Without it, the model makes the right decision 75% of the time, but it closes with an answerable question only 21% of the time. The skill matters most for the close and for the facts, not for the decision itself.

The six repeat scores have a standard deviation of 0.052. From that, the acceptance rule is:

- **Total:** the candidate total must stay above the baseline total minus `2 × 0.052 × √(1/3 + 1/6)`, a margin of 0.074.
- **Each measure:** each rate must stay above the baseline rate minus two binomial standard errors, a margin of 0.14 to 0.20.

I checked the rule in both directions. The second baseline run passes against the first. The control fails.

The baseline also failed where I failed in real life. In the case that rebuilds my first incident, all 6 samples led with the fix inside my frame, not the leftover crontab line at the source. In the denylist case, all 6 samples still offered the denylist as an alternative.

## The cut

A separate agent read the reports and wrote the candidate. The rules for it were strict: under 200 lines, keep the 80-column wrap so that joined lines cannot fake the count, keep the self-debate and the alternative definition, and never change a test to make a candidate pass. It could only propose test changes. I reviewed them, because each one forces both baselines to run again.

It deleted the `Do not` list, because every item repeated a rule from another section. It deleted the trigger list, which the skill description already holds. It merged four rules about the fixed timeline into one sentence. It also added a few lines that target repeated failures: read the files before any message, call a fact unverified only after a search, rank the option that removes the root cause above a guard against the symptom, and treat an option that the user proposed like any other option.

Both columns pool two runs with 3 repeats each:

| Measure | 267-line skill | 192-line skill |
| --- | --- | --- |
| Total | 0.716 | 0.872 |
| M1 Right decision | 0.861 | 1.000 |
| M2 True facts | 0.702 | 0.881 |
| M3 No follow-up | 0.567 | 0.789 |
| M4 Understanding | 0.821 | 0.917 |
| M5 Answerable close | 0.679 | 0.905 |
| M7 Valid alternative | 0.682 | 0.727 |

The skill went from 2200 words to 1638. The messages went from 402 words to 389 on average.

## The holdout

The agent that wrote the candidate read the answer keys. Part of the gain can fit those 16 cases and nothing else. So a fresh agent wrote 14 holdout cases, 2 per measure, with new projects and new root causes. It was not allowed to read the candidate or its runs.

| Measure | 267-line skill | 192-line skill |
| --- | --- | --- |
| Total | 0.785 | 0.856 |
| M2 True facts | 0.833 | 0.944 |
| M3 No follow-up | 0.736 | 0.778 |
| M5 Answerable close | 0.833 | 0.931 |
| M7 Valid alternative | 0.652 | 0.636 |
| MF Factual answer | 0.250 | 0.750 |

The gain holds. The holdout also found two things that the main set missed. First, the old skill put the full template on one-line factual questions: a simple "which Node version does CI use" got a four-step timeline. Second, alternatives did not improve. M7 is flat and it is still the weakest measure.

## Same skill, a larger model

Next, I ran the 192-line skill with Opus as the generator, once at medium effort and once at high effort. The reader and the grader stayed on Sonnet, so the scores compare directly. Each Sonnet value pools two runs. Each Opus value is one run. All runs have 3 repeats.

On the main cases:

| Measure | Sonnet medium | Opus medium | Opus high |
| --- | --- | --- | --- |
| Total | 0.872 | 0.840 | 0.864 |
| M1 Right decision | 1.000 | 0.972 | 0.972 |
| M2 True facts | 0.881 | 0.762 | 0.833 |
| M3 No follow-up | 0.789 | 0.800 | 0.778 |
| M4 Understanding | 0.917 | 0.881 | 0.905 |
| M5 Answerable close | 0.905 | 0.905 | 0.881 |
| M7 Valid alternative | 0.727 | 0.697 | 0.818 |
| MF Factual answer | 1.000 | 1.000 | 1.000 |
| M6 mean words | 389 | 465 | 472 |
| Generation cost per run | 1.67 USD | 3.78 USD | 4.80 USD |

On the holdout cases:

| Measure | Sonnet medium | Opus medium | Opus high |
| --- | --- | --- | --- |
| Total | 0.856 | 0.861 | 0.847 |
| M1 Right decision | 0.970 | 0.909 | 0.879 |
| M2 True facts | 0.944 | 0.889 | 0.889 |
| M3 No follow-up | 0.778 | 0.917 | 0.889 |
| M4 Understanding | 0.889 | 0.861 | 0.889 |
| M5 Answerable close | 0.931 | 0.917 | 0.889 |
| M7 Valid alternative | 0.636 | 0.636 | 0.636 |
| MF Factual answer | 0.750 | 1.000 | 0.833 |
| M6 mean words | 421 | 500 | 520 |
| Generation cost per run | 1.86 USD | 4.52 USD | 5.88 USD |

All four Opus runs pass the acceptance rule against the Sonnet baselines. None of them is better than Sonnet by more than the noise.

The first Opus run found a defect in the eval. My global gitignore holds `**/*.env`, so git did not commit the two `.env` files of the factual case. Opus got an empty directory, said so, and asked for the path. That is the correct answer, but it failed MF. I restored the files and generated that case again. The tables show the corrected values.

The larger model did not make better rulings. It closed with fewer follow-up questions on the holdout, but it lost points on M2. Most of its M2 fails are hedges such as "Unverified: X", when a file in the fixture settles X. Opus wrote about twice as many of these hedges per run as Sonnet. High effort recovered part of M2 and gave the best M7 on the main cases, but M7 stayed flat on the holdout. Opus messages were 20% longer. Generation cost 2.3 to 3.2 times more. For this skill, Sonnet stays the generator.

## What I take away

- **Write the goal as one sentence before the first test.** My first eval set was large, mechanical and wrong. The goal sentence turned 299 checks into 7 measures.
- **Run a control.** Without the empty-skill run, I would not know that the model makes the right decision 75% of the time on its own. The skill earns its lines on the close and the facts.
- **Measure the noise before you set the bar.** Two baseline runs differed by 0.042. A bar narrower than the noise fails good candidates. I saw it happen: with one stored run as the baseline, the 192-line skill failed against itself on the holdout, 0.824 against 0.889. Two baseline runs fixed that.
- **Keep a holdout from the editor.** The agent that edits the skill must not grade on the same keys that it read.
- **A larger model is not a free gain.** Opus did not beat Sonnet on this skill. It cost more than twice as much and wrote longer messages.
- **The eval has limits.** The generator, the reader and the grader are the same model family. The keys are one author's judgment. Only 6 of 30 cases are hard enough that the model fails without the skill, and I invoke `/explain` only for hard decisions. That is the next gap to close.

The eval set lives next to the skill in [kanthorlabs/dotagents](https://github.com/kanthorlabs/dotagents/tree/main/evals). The shared scripts are in `evals/harness/`, and each skill gets its own suite directory, so the next skill only needs cases and a grader. When I change a skill, I run its suite again and compare against the two stored baseline runs.
