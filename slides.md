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

**It depends.**

::: notes
- Shiny is for automating tasks and visualizing quickly
- If the app exists and works, even if perceived to be slow, it provides utility
- Faster is always better
- Apps that see a lot of use can give users higher efficiency if they load faster, have shorter response times
:::

## Constraints

* Performance of underlying process
  * Computation, network
* Organization priorities
  * 10 more apps or 1 app 10x faster?
* Usage profile
  * One person once a month generates a report

::: notes
- Factors influencing what 'fast' means in context
- In a business/org setting 'fast enough' is based on more than an individual user's experience
  - 'fast enough' for an individual vs. 'good enough'
- Underlying process: 3rd party computational process or network process. API, DB (Redshift), etc
  - May have some control over these, may not
:::

# Section Two

## Slide C

content

[RAIL]: https://developers.google.com/web/fundamentals/performance/rail
