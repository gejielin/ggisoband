#' Draw isoband and isoline contours
#'
#' Draw isoband and isoline contours.
#' @inheritParams ggplot2::layer
#' @inheritParams ggplot2::geom_point
#' @inheritParams stat_isolevels
#' @param polygon_outline Draw filled polygons with equally colored outlines? The
#'   default is `TRUE`, which works well in cases where isobands are drawn without
#'   colored isolines. However, it can create drawing artifacts when used in
#'   combination with alpha transparency.
#' @examples
#' library(ggplot2)
#'
#' volcano3d <- reshape2::melt(volcano)
#' names(volcano3d) <- c("x", "y", "z")
#'
#' ggplot(volcano3d, aes(x, y, z = z)) +
#'   geom_isobands(aes(color = stat(zmin)), fill = NA) +
#'   scale_color_viridis_c() +
#'   coord_cartesian(expand = FALSE) +
#'   theme_bw()
#'
#' ggplot(volcano3d, aes(x, y, z = z)) +
#'   geom_isobands(aes(fill = stat(zmin)), color = NA) +
#'   scale_fill_viridis_c(guide = "legend") +
#'   coord_cartesian(expand = FALSE) +
#'   theme_bw()
#'
#' # set polygon_outline = FALSE when drawing filled polygons
#' # with alpha transparency
#' ggplot(volcano3d, aes(x, y, z = z)) +
#'   geom_isobands(
#'     aes(fill = stat(zmin)), color = NA,
#'     alpha = 0.5, polygon_outline = FALSE
#'   ) +
#'   scale_fill_viridis_c(guide = "legend") +
#'   coord_cartesian(expand = FALSE) +
#'   theme_bw()
#'
#' ggplot(faithful, aes(eruptions, waiting)) +
#'   geom_density_bands(
#'     aes(fill = stat(density)),
#'     color = "gray40", alpha = 0.7, size = 0.2
#'    ) +
#'   geom_point(shape = 21, fill = "white") +
#'   scale_fill_viridis_c(guide = "legend")
#' @export
geom_isobands <- function(mapping = NULL, data = NULL,
                          stat = "isolevels", position = "identity",
                          ...,
                          bins = NULL, binwidth = NULL, breaks = NULL,
                          polygon_outline = TRUE,
                          na.rm = FALSE, show.legend = NA, inherit.aes = TRUE) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomIsobands,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      polygon_outline = polygon_outline,
      bins = bins,
      binwidth = binwidth,
      breaks = breaks,
      na.rm = na.rm,
      ...
    )
  )
}

#' @rdname geom_isobands
#' @export
geom_density_bands <- function(mapping = NULL, data = NULL,
                               stat = "densitygrid", position = "identity",
                               ...,
                               bins = NULL, binwidth = NULL, breaks = NULL,
                               polygon_outline = TRUE,
                               na.rm = FALSE, show.legend = NA, inherit.aes = TRUE) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomIsobands,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      polygon_outline = polygon_outline,
      bins = bins,
      binwidth = binwidth,
      breaks = breaks,
      na.rm = na.rm,
      ...
    )
  )
}


#' @rdname geom_isobands
#' @format NULL
#' @usage NULL
#' @export
GeomIsobands <- ggproto("GeomIsobands", Geom,
  required_aes = c("x", "y", "z"),
  default_aes = aes(
    # contour lines
    colour = "black", size = 0.5, linetype = 1, alpha = NA,
    # contour polygons
    fill = "gray70", fill_alpha = NULL
  ),
  nonmissing_aes = c("zmin", "zmax"),

  draw_group = function(data, panel_params, coord, polygon_outline = TRUE) {
    z <- tapply(data$z, data[c("y", "x")], identity)

    if (is.list(z)) {
      stop("Contour requires single `z` at each combination of `x` and `y`.",
           call. = FALSE)
    }

    x <- sort(unique(data$x))
    y <- sort(unique(data$y))
    zmin <- sort(unique(data$zmin))
    zmax <- sort(unique(data$zmax))

    aesthetics <- data[match(zmin, data$zmin), , drop = FALSE]

    bands <- isobands(x, y, z, zmin, zmax)
    bandgrobs <- list()
    j <- 1
    for (i in seq_along(bands)) {
      coords <- coord$transform(bands[[i]], panel_params)
      if (length(coords$x) > 0) {
        fill <- alpha(aesthetics$fill[i], aesthetics$fill_alpha[i] %||% aesthetics$alpha[i])
        if (isTRUE(polygon_outline)) {
          col <- fill
        } else {
          col <- NA
        }
        gp <- gpar(
          col = col,
          fill = fill,
          lwd = aesthetics$size*.pt
        )
        bandgrobs[[j]] <- pathGrob(coords$x, coords$y, coords$id, gp = gp)
        j <- j + 1
      }
    }

    linebreaks <- zmin[2:length(zmin)]
    lines <- isolines(x, y, z, linebreaks)
    linegrobs <- list()
    j <- 1
    for (i in seq_along(lines)) {
      coords <- coord$transform(lines[[i]], panel_params)
      if (length(coords$x) > 0) {
        gp <- gpar(
          col = alpha(aesthetics$colour[i+1], aesthetics$alpha[i]),
          lwd = aesthetics$size*.pt,
          lty = aesthetics$linetype
          )
        linegrobs[[j]] <- polylineGrob(coords$x, coords$y, coords$id, gp = gp)
        j <- j + 1
      }
    }

    do.call(grobTree, c(bandgrobs, linegrobs))
  },

  draw_key = draw_key_polypath
)

