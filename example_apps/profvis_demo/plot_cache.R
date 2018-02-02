#' SOURCE: https://github.com/wch/shiny_demo/blob/master/cran_explorer/plot_cache.R
#' Disk-based plot cache
#'
#' Creates a read-through cache for plots. The plotting logic is provided as
#' plotFunc, a function that can have any number/combination of arguments; the
#' return value of plotCache is a function that should be used in the place of
#' plotFunc. Each unique combination of inputs will be cached to disk in the
#' location specified by cachePath.
#'
#' The invalidationExpr expression will be monitored and whenever it is
#' invalidated, so too is the cache invalidated (the contents are erased).
#'
#' @param cacheId An identifier for this cache; by default, will be incorporated
#'   into the cache directory path.
#' @param invalidationExpr Any expression or block of code that accesses any
#'   reactives whose invalidation should cause cache invalidation. Use NULL if
#'   you don't want to cause cache invalidation.
#' @param width,height The dimensions of the plot. (Use double the user
#'   width/height for retina/hi-dpi compatibility.)
#' @param res The resolution of the PNG. Use 72 for normal screens, 144 for
#'   retina/hi-dpi.
#' @param plotFunc Plotting logic, provided as a function that takes zero or
#'   more arguments. Don't worry about setting up a graphics device or creating
#'   a PNG; just write to the graphics device (don't forget to call print() on
#'   ggplot2 objects).
#' @param cachePath The location on disk where the cache will be stored. By
#'   default, uses a temp directory, which is generally cleaned up during a
#'   normal shutdown of the R process.
plotCache <- function(cacheId, invalidationExpr, width, height, res = 72,
                      plotFunc,
                      cachePath = file.path(tempdir(), cacheId),
                      invalidation.env = parent.frame(),
                      invalidation.quoted = FALSE) {
  
  message("Using cache path ", cachePath)
  dir.create(cachePath, recursive = TRUE, mode = "0700")
  
  if (!invalidation.quoted) {
    invalidationExpr <- substitute(invalidationExpr)
  }
  
  shiny::observeEvent(invalidationExpr, event.env = invalidation.env, event.quoted = TRUE, {
    # TODO: robustify
    if (dir.exists(cachePath)) {
      file.rename(cachePath, paste0(cachePath, ".gone"))
    }
    dir.create(cachePath, recursive = TRUE, mode = "0700")
    unlink(paste0(cachePath, ".gone"), recursive = TRUE)
  })
  
  function(...) {
    args <- list(...)
    key <- paste0(digest::digest(args), ".png")
    filePath <- file.path(cachePath, key)
    if (!file.exists(filePath)) {
      message("Cache miss")
      shiny::plotPNG(function() {
        do.call("plotFunc", args)
      }, filename = filePath, width = width, height = height, res = res)
    } else {
      message("Cache hit")
    }
    filePath
  }
}
