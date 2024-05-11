---
title: Versioning System
date: 2024-05-11 14:00:00 +0700
categories: [Solution]
tags: [gitflow]
---

An evolution of the way I create software versions: from a novice coder to my own definition of versioning.

## Self awareness

Long ago, when I first entered the industry and began using Git as a version control system, everyone told me that when I wanted to release something, I needed to tag it. The tag had to follow a format of three numbers separated by two dots. I was too young to ask why we needed that thing; I just followed their advice.

After several years, as I gained more experience in IT development life cycles, I came to understand that the tagging convention I was told about earlier is known as semantic versioning, or [SemVer](https://semver.org/). Each number in the tag holds significance, and developers have established conventions around these three numbers. However, I also realized that configuring a release by incrementing one of those numbers from the old version can be cumbersome in the CI/CD workflow. It required me to write custom bash scripts to extract and increment them, which was a bad experience.

I've been frustrated for a long time, especially when I needed to release three to five versions each week. When one of them went wrong, I had to roll it back. It was during these moments that I discovered a crucial fact: a version is simply a snapshot of your stable codebase or a usable version with some acceptable bugs. So, as long as the version indicates its purpose, I believed I could create a wonderful version using any format. However, when I applied this mindset, the toolset I was using responded with a resounding "NO, you can't." I messed up the entire CI/CD workflow because no new versions were deployed for all the services I had been maintaining. The CD toolset required semantic versioning to differentiate versions and pick up the newest. Okay, I'm fine.

## A journey to discover a perfect versioning system I need

The first format version that caught my attention is the Ubuntu versioning system. They consistently release two versions each year: one in April, denoted as `xx.04`, and the other in October, denoted as `xx.10`. This system indicates the month of the version's release, making it easy to track. Additionally, Ubuntu follows a convention where the April release is designated as the Long-Term Support (LTS) version, while the October version is not.

The second version format that I find interesting is the CockroachDB versioning system. They use the format `yy.M.x`, where the major version represents the year and the minor version indicates the month of release. Attached is a screenshot for your reference, so you can see it for yourself.

![cockroachdb-versioning-system](/assets/img/2024-05-11-cockroachdb-versioning-system.png)

Both versioning systems share similar characteristics: they not only indicate the version but also convey the time of release as additional information. These versions facilitate scheduling; you can simply set the release time on your CI system and choose the year and month as the version, eliminating the need to manage increasing major and minor version numbers.

However, neither of these versioning systems is ideal for my needs. The Ubuntu versioning system, which relies on biannual releases, does not align with my requirement for more frequent updates. Similarly, while the CockroachDB versioning system offers granular versioning by indicating the year and month of release, it necessitates manual adjustment of the patch version for every patch release, rendering it impractical for my purposes. Therefore, it is time for me to define my own versioning system.

## Define my own versioning system

Before define a versioning system I need, let's explore what requirements should be sastified by that system first

- First of all, it need to be easy to generate. I don't want to write a bash script to increase the version number anymore
- Prevent collision between two version when I need to release new version frequently. This requirement came from the fact that after almost release, we need to deploy many patches. Yes, it's insanse but I used to put a patch to fix a bug then need to put another patch to fix a bug that was happen in the previous patch ;D

Requirements are clear, so let me introduce you to the first format I've used: `yyyy.MMdd.HHmm`. An example of that format is `2024.0511.1530`. As long as I cannot patch a bug in a minute and the CI/CD can run within a minute, I’m safe with that format. There's no way I can release a patch within the same minute, can I?

And that format didn’t work. Do you remember that I mentioned I messed up the CI/CD system, and none of the services were deployed before? Yes, it happened because of the format `yyyy.MMdd.HHmm`. The question is, why doesn't the CI/CD system, which uses SemVer, work with a version like `2024.0511.1530`? To answer that question, let’s go to the [SemVer](https://semver.org/) website and press `Ctrl + F` to find the phrase `leading zero`. Then you can see this rule.

![semver-leading-zero](/assets/img/2024-05-11-semver-leading-zero.png)

So, `2024.0511.1530` didn’t work because it contains a leading zero in the minor version. To fix it, just use the format `yyyy.Mdd.HHmm`. Then everything works well as I expected. Some examples are

- `2024.511.1530`
- `2024.1211.1530`
- `2024.1225.1530`

## Bonus

Some conventions I have also defined while exploring the versioning system are:

- Use UTC timestamp to define the patch so different teams in different time zones can have the same version.
- Use Local timestamp to schedule the release, allowing us to identify the team responsible for scheduling. For example, the VN team with a UTC+07:00 timezone scheduling a release at midnight will use the version `xxxx.xxxx.1701`, while the SG team with a UTC+08:00 timezone will use the version `xxxx.xxxx.1601` to schedule their release.
