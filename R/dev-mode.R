#' Activate and deactivate development mode.
#'
#' When activated, `dev_mode` creates a new library for storing installed
#' packages. This new library is automatically created when `dev_mode` is
#' activated if it does not already exist.
#' This allows you to test development packages in a sandbox, without
#' interfering with the other packages you have installed.
#'
#' @param on turn dev mode on (`TRUE`) or off (`FALSE`).  If omitted
#'  will guess based on whether or not `path` is in
#'  [.libPaths()]
#' @param path directory to library.
#' @export
#' @examples
#' \dontrun{
#' dev_mode()
#' dev_mode()
#' }
dev_mode <- local({
  .prompt <- NULL

  function(on = NULL, path = getOption("devtools.path")) {
    lib_paths <- .libPaths()

    path <- normalizePath(path, winslash = "/", mustWork = FALSE)
    if (is.null(on)) {
      on <- !(path %in% lib_paths)
    }

    if (on) {
      if (!file.exists(path)) {
        dir.create(path, recursive = TRUE, showWarnings = FALSE)
      }
      if (!file.exists(path)) {
        stop("Failed to create ", path, call. = FALSE)
      }

      if (!is_library(path)) {
        warning(path, " does not appear to be a library. ",
          "Are sure you specified the correct directory?",
          call. = FALSE
        )
      }

      cli::cli_alert_success("Dev mode: ON")
      options(dev_path = path)

      if (is.null(.prompt)) .prompt <<- getOption("prompt")
      options(prompt = paste("d> "))

      .libPaths(c(path, lib_paths))
    } else {
      cli::cli_alert_success("Dev mode: OFF")
      options(dev_path = NULL)

      if (!is.null(.prompt)) options(prompt = .prompt)
      .prompt <<- NULL

      .libPaths(setdiff(lib_paths, path))
    }
  }
})

is_library <- function(path) {
  # empty directories can be libraries
  if (length(dir(path)) == 0) return(TRUE)

  # otherwise check that the directories are compiled R directories -
  # i.e. that they contain a Meta directory
  dirs <- dir(path, full.names = TRUE)
  dirs <- dirs[utils::file_test("-d", dirs)]

  has_pkg_dir <- function(path) length(dir(path, pattern = "Meta")) > 0
  help_dirs <- vapply(dirs, has_pkg_dir, logical(1))

  all(help_dirs)
}
