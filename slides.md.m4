changequote(`"""', `"""')
---
author: <a href="https://twitter.com/alandipert">Alan Dipert (@alandipert)</a>
title: Make Shiny Fast
subtitle: ...by doing as little work as possible
date: February 2, 2018
---

## Agenda

1. Introduce methodology
1. Learn to measure, analyze with `Rprof` & `profvis`
1. CRAN Explorer optimization tour

::: notes
- methodology: introduce a way of thinking about optimization that will serve you well in practice
- rprfo/profvis: focus on this because involves new tools
- cran explorer: learn about how experts tackle in practice
    - rules of thumb
:::

## Optimization Loop Method

<img style="width:100%;" data-src="diagrams/loop.svg"/>

::: notes
* primary methodology: series of steps, applied in the face of an optimization question
* what should pop in your mind when someone tells you it's too slow
    * easy to get lost in details, back alleys in the pursuit of performance
    * keep a lab notebook. scientific method


1. benchmark: determine if it's fast enough, know where you stand
1. analyze: figure out what's slow
1. recommend: estimate work to make it fast
1. optimize: make it fast, if it makes sense
:::

# Benchmark

## What's in a benchmark?

1. **Model**: Representative user actions
1. **Metrics**: Latencies experienced by model user

::: notes
1. model: idea about how the app will be used. what's in your head when you made it
1. metrics: how long the user will wait when they use the app as you intended
:::

## Model example

*Reserving flights*

<video controls><source data-src="videos/travelocity.mp4" type="video/mp4"></video>

::: notes
- Look at a model
- Measure latencies
:::

## 😱 

**Results took > 20 seconds!**

It's OK.

* Users expect to wait, UI confirms expectation
* It's Fast Enough™

::: notes
- importance of appropriate UI elements, attention to UX
- something about dev culture: willing to sacrifice all for perf
- don't worry about other peoples benchmarks, just focus on making your users happy and solving real problems
:::

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

# In Practice

## CRAN explorer

<img style="width:100%;border:none;" data-src="screenshots/cran_explorer.png"/>

## Optimizing CRAN explorer

* [https://github.com/wch/shiny_demo/](https://github.com/wch/shiny_demo/)
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

~~~{.R}
microbenchmark(
  read_csv("packages.csv"),
  readRDS("packages.rds")
)
~~~

|expr|mean
-|-:
|`read_csv("packages.csv")`|661.4826
|`readRDS("packages.rds")`|851.1554

::: notes
- Helps with startup
- Speeds up load for 1st session to hit shiny process
:::

## Sidenote: scopes

* R process-global (top-level)
* Per-session (inside `server` function)

~~~{.R}
all_data <- reactiveVal(read_csv("packages.csv"))
~~~
[app.R at 698b8fc](https://github.com/wch/shiny_demo/blob/698b8fca49bf672f83e90a0a1dbc29fe5f640042/cran_explorer/app.R#L13)

::: notes
- Data could be read from disk every time and app would still be "correct"
- Picking appropriate scope to store data form of optimization
:::

## Optimization #4: Plot caching

<img style="width:100%;border:none;" data-src="screenshots/timeline.png"/>

* `plotCache`: read-through cache for plots
* Coming soon to Shiny

::: notes
- plotting is expensive
- helper function to re-plot only when inputs change
- previously-generated image served up in meantime
- in cran explorer app, plots are the same for each value of `all_data`
- app_caching.R in example_apps
:::

## Thank you!

<a href="https://twitter.com/alandipert">https://twitter.com/alandipert</a>

<a href="https://github.com/alandipert">https://github.com/alandipert</a>

[RAIL]: https://developers.google.com/web/fundamentals/performance/rail
[METACRAN]: https://r-pkg.org/
