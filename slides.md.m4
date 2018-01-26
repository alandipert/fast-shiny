changequote(`"""', `"""')
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

<img style="width:100%;" data-src="diagrams/loop.svg"/>

# Benchmark

## What's in a benchmark?

1. **Model**: Representative user actions
1. **Metrics**: Latencies experienced by model user

## Model example

*Reserving flights*

<video controls><source data-src="videos/travelocity.mp4" type="video/mp4"></video>

## 😱 

Returning results took > 20 seconds!

* Users expect and UI confirms
* Not frustrated, not leaving
* It's Fast Enough™

## Benchmarking in practice

Best done casually!

<video autoplay loop><source data-src="videos/thumbsup.mp4" type="video/mp4"></video>

* Fast Enough is easy to see
* Only when it's *not* Fast Enough must we Analyze

# Analyze

## Analysis

1. Exercise model to produce *metric data*
1. Identify the **one slowest thing**

Optimizing slowest thing gives highest payoff

## `Rprof` and `profvis`

* "Feels slow" usually means R is busy
* `Rprof`: sample what R is doing
    * Computing (`ggplot2`, `dplyr`)
    * Waiting (database, network, disk)
* `profvis`: visualize `Rprof` output

## The *call stack*

:::::: {.columns}
::: {.column}
### Code
~~~{.R}
inner <- function(x) { 
  stop("oh no")
}
middle <- function(x) { x }
outer <- function(x) { x }

outer(middle(inner()))
~~~
Each call creates a *frame* on the *call stack*
:::
::: {.column}
### Stack
<img style="border:none;width:100%;" data-src="diagrams/stack_growth.svg"/>
:::
::::::

## Traceback

<video controls autoplay loop><source data-src="videos/traceback.mp4" type="video/mp4"></video>

## Call stack over time

:::::: {.columns}
::: {.column width="35%"}
~~~{.R}
outer(middle(inner()))
outer(middle(inner()))
outer(middle(inner()))
~~~
:::
::: {.column width="65%"}
<img style="border:none;width:100%;" data-src="diagrams/stacks.svg"/>
:::
::::::

## 🤔

:::::: {.columns}
::: {.column}
~~~{.R}
delay <- function(expr) {
  profvis::pause(1)
  force(expr)
}

delay(delay(delay(1)))
~~~
What if width represented duration?
:::
::: {.column}
<img style="border:none;width:100%;" data-src="diagrams/timestacks.svg"/>
:::
::::::

## `profvis` in action

:::::: {.columns}
::: {.column width="40%"}
~~~{.R}
library(profvis)
delay <- function(expr) {
  profvis::pause(1)
  force(expr)
}

profvis({
  delay(delay(delay(1)))
})
~~~
:::
::: {.column width="60%"}
<img style="border:none;width:100%;" data-src="screenshots/profvis.png"/>
:::
::::::

::: notes
- Flame graph original idea, Brendan Gregg Netflix
- Flame chart vs. flame graph
    - Flame chart: x axis is time
        - See Chrome devtools
    - Flame graph: x axis is number of times frame occurred
:::

## Short `profvis` Demo

`example_apps/profvis_demo`

## A small program

:::::: {.columns}
::: {.column}
~~~{.R}
include("""plots/rprof_example.R""")
~~~
:::
::: {.column}
<img style="width:100%;border:none;" data-src="plots/rprof_example.png"/>
:::
::::::

# In Practice

## CRAN explorer

<img style="width:100%;border:none;" data-src="screenshots/cran_explorer.png"/>

## Optimizing CRAN explorer

* Built by Winston Chang
* My account of optimization work by Winston and Joe Cheng

## Organization

:::::: {.columns}
::: {.column}
~~~
cran_explorer/
├── app.R
├── deps.csv
├── packages.csv
├── plot_cache.R
└── utils.R
~~~
:::
::: {.column}
* `app.R`: Shiny app
* `deps.csv`, `packages.csv`: data
* `plot_cache.R`: Disk-based plot cache
* `utils.R`: Download, prepare `.csv` files
:::
::::::

## Architecture

* `utils.R` for downloading `.csv` files
* Data loaded as global `reactiveVal`s on `app.R` startup
* `dplyr` used to search, filter
* `ggplot2` used for plots

## Optimization #1: Pre-process

* Didn't download from METACRAN every time
* Winston's experience saved time
* **Rule of thumb: if the data is big, pre-process**

## Optimization #2: Beware `dplyr::group_by()`

> `group_by()` takes an existing tbl and converts it into a grouped tbl where operations are performed "by group".

## `group_by()` example

~~~{.R}
> mtcars %>% summarise(disp = mean(disp), hp = mean(hp))
      disp       hp
1 230.7219 146.6875
> mtcars %>% 
    group_by(cyl) %>% 
    summarise(disp = mean(disp), hp = mean(hp))
    cyl     disp        hp
  <dbl>    <dbl>     <dbl>
1     4 105.1364  82.63636
2     6 183.3143 122.28571
3     8 353.1000 209.21429
~~~

## `filter()` after `group_by()` Slowdown

~~~{.R}
mtcars %>% filter(disp > 200) # 2.99 sec
mtcars %>% group_by(cyl) %>% filter(disp > 200) # 3.93 sec
~~~

* First `filter` applied only to `mtcars`
* Second `filter` applied to each group

::: notes
- Only 3 groups (6, 4, 8 cyl)
- 12k+ packages
- Ticket: https://github.com/tidyverse/dplyr/issues/3294
:::

## Offending `reactive`

~~~{.R}
packages_released_on_date <- reactive({
  req(input$date)
  all_data %>%
    filter(date <= input$date) %>%
    group_by(Package) %>%               # <--
    filter(any(date == input$date)) %>% # <--
    summarise(
      Version = first(Version),
      total_releases = n()
    ) %>%
    ungroup()
})
~~~
[app.R at 0f7560](https://github.com/wch/shiny_demo/blob/0f7560c1701cca5fc11637a810e78d2f55d1d9ab/cran_explorer/app.R#L132-L143)


## Optimization #3: CSVs read faster than RDS

## Optimization #2: Solution

* Avoid filtering after grouping
* Join, mutate, filter instead

## Optimization #3: CSV instead of RDS

## Optimization #4: Disk-backed plot cache

[RAIL]: https://developers.google.com/web/fundamentals/performance/rail
[METACRAN]: https://r-pkg.org/
