---
author: <a href="https://twitter.com/alandipert">Alan Dipert (@alandipert)</a>
title: Make Shiny Fast
subtitle: ...by doing as little work as possible
date: February 2, 2018
---

# What's "fast'?

## Answer #1

*A decent answer.*

* Load time
* Response time

## Google's RAIL Model

> [RAIL][RAIL] is a user-centric performance model that breaks down the user's experience into key actions. 

* **R**esponse
* ~~**A**nimation~~
* ~~**I**dle~~
* **L**oad

::: notes
- Google 2009 "Speed Matters" study: > 100ms loses customers
- Shiny apps a special case: animation and usually managed by framework
- RAIL great entrypoint to world of speed concerns on the web
:::

## Perceptions of Delay

| Delay (ms) | Emoji | Effect
-|-|-:
| 0 to 100 |😀| Feels immediate
| 100 to 300 |🙂| Perceive slight delay
| 300 to 1000 |😐| Still on task
| > 1000 |😕| Lose focus
| > 10000 |😱 |Frustration, abandonment

::: notes
- Summary of Response section of RAIL
- delay in milliseconds (1/1000th of second)
- 300 to 1000ms: "For most users on the web, loading pages or changing views represents a task."
- > 10000ms: "users are frustrated and are likely to abandon tasks. They may or may not come back later."
:::

## Answer #2

*The real answer.*

Fast means: **fast enough** for your users, given:

* organizational priorities
* deadlines
* external dependencies
* inviolable constraints

::: notes
- external deps: 3rd party APIs, databases
- inviolable: available hardware, speed of light
- One user's perception of speed has value, but the overall value of a Shiny app is composite
- A "slow" app could totally solve a problem to the satisfaction of everyone involved
  - one user runs one report once a month
- Faster is always better
  - Fast apps can make users more efficient, provide more overall value
:::

# Fast Enough

## The Optimization Loop

<img style="width:100%;" src="diagrams/loop.svg"/>

[RAIL]: https://developers.google.com/web/fundamentals/performance/rail
