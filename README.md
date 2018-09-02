# journocoders-geogrid

In this tutorial we will learn to make hexagonal grids using the [geogrid](https://github.com/jbaileyh/geogrid) package and use the resulting geometry with D3. This is a simplified version of the author's own reference, aimed at getting the spatial data out of R.

## Install R

First you need to install R. If you're using macOS you can simply use [homebrew](https://brew.sh) with `brew install R`. If you use GNU/Linux, please refer to your package manager. If you use Windows you can [install R through CRAN](https://cran.rstudio.com/).

Once you have R installed please do get [RStudio](https://www.rstudio.com/products/rstudio/download/#download). It is a comfortable environment to write R code, with inline documentation and examples.

## Install geogrid

After you have a R setup we can proceed to install geogrid. The standard way to get packages is by calling `install.packages`, so you can do `install.packages('geogrid')` in the R console.

However, I've had problems doing this with the latest R as by default there are some conflicting packages (`units` and `sf`).

To fix this first do

```sh
$ brew install udunits
```

And then install `gdal2`

```sh
$ brew install gdal2
```

After that we need to tell R more information about our compiler per [#814](https://github.com/r-spatial/sf/issues/814#issuecomment-417535690).

```sh
$ mkdir ~/.R && printf "CC=clang\nCXX=clang++ -std=gnu++11\nPKG_CXXFLAGS= -stdlib=libc++ -std=c++11" >> ~/.R/Makevars

```

And finally compile `sf`

```r
install.packages("sf", type = "source", configure.args=c(
  "--with-gdal-config=/usr/local/opt/gdal2/bin/gdal-config",
  "--with-proj-include=/usr/local/opt/proj/include",
  "--with-proj-lib=/usr/local/opt/proj/lib"))
```

Now we can install `geogrid`

```r
install.packages("geogrid")
```

## Install geojsonio

We will use [geojsonio](https://github.com/ropensci/geojsonio) to write a TopoJSON file from R. This is also troublesome. Make sure to look at their README for more information.

First install a specific version of `v8`

```sh
$ brew install v8@3.15
```

Now let's install `rgdal` with our brewed gdal

```r
install.packages("rgdal", type = "source", configure.args="--with-gdal-config=/usr/local/opt/gdal2/bin/gdal-config")
```

Now we can install `geojsonio`

```r
install.packages("geojsonio")
```

## Using geogrid

If you made it here, congrats! It can take a while to get `gdal2` to cooperate.

Now we will use `geogrid` to generate some hexagons of the [Local Authorities](http://geoportal.statistics.gov.uk/datasets/local-authority-districts-december-2017-super-generalised-clipped-boundaries-in-great-britain). You can find the whole R code in `script.R`, here we will go step by step.

### Seeding the grid

First, we need to load the library and switch to the project folder

```r
library(geojsonio)
library(geogrid)

setwd("~/YOUR/LOCAL/FOLDER/journocoders-geogrid/")
```

Now, we're ready to read our shapefile

```r
df <- read_polygons("src/Local_Authority_Districts_December_2017_Super_Generalised_Clipped_Boundaries_in_Great_Britain.shp")

```

We can set the arguments for `plot` to render different variations of our grid

```r
par(mfrow = c(2, 3), mar = c(0, 0, 2, 0))
```

And now we can loop with `calculate_grid` to get multiple hexagon grids

![Hexagon grid](https://user-images.githubusercontent.com/1236790/44955703-a7a63e80-aeaf-11e8-95bb-75c83e86d7bb.png)

```r
for (i in 1:6) {
  grid_hexagon <- calculate_grid(shape = df, grid_type = "hexagonal", seed = i)
  plot(grid_hexagon, main = paste("Seed", i, sep = " "))
}
```

Let's see how does it look using squares

![Square grid](https://user-images.githubusercontent.com/1236790/44955723-010e6d80-aeb0-11e8-9bb3-94f330bc474c.png)

```r
for (i in 1:6) {
  grid_square <- calculate_grid(shape = df, grid_type = "regular", seed = i)
  sp::plot(grid_square, main = paste("Seed", i, sep = " "))
}
```

### Exporting map

When you find a seed that you're comfortable with we retrieve it individually.

```r
tmp <- calculate_grid(shape = df, grid_type = "hexagonal", seed = 5)
```

Now let's retrieve a SpatialDataFrame out of the hexagon. This will take a long time, in my case it was like an hour.

```r
df_hex <- assign_polygons(df, tmp)
```

And now you can export it to TopoJSON (you can inspect the resulting file with [mapshaper](http://mapshaper.org))

![Mapshaper](https://user-images.githubusercontent.com/1236790/44956344-50f23200-aeba-11e8-90b9-cbd36265f866.png)

```r
topojson_write(df_hex, object_name = "local_authorities", file = "output/local_authorities.json")
```

## Visualising with D3

Now that we have the geometry, let the fun begin. If you don't have it already, please install a local http server to preview the map. If you have macOS, open the terminal (open Spotlight with <kbd>⌘ + space</kbd> and search for terminal), navigate to the project folder and run the built-in Python server

```sh
$ cd ~/YOUR/PROJECT/FOLDER/journocoders-geogrid && python -m SimpleHTTPServer
```

If you use Windows or Linux you can also use that if you have Python installed, but in general I recommend to install [node](https://nodejs.org/en/download/) and use `http-server` instead.

```
npm i -g http-server
```

And the same applies

```sh
$ cd ~/YOUR/PROJECT/FOLDER/journocoders-geogrid && http-server
```

Now you can open the same folder with your code editor of choice and go to `index.html`.

### Rendering the map

We will visualise [job density](https://www.nomisweb.co.uk/query/construct/summary.asp?mode=construct&version=0&dataset=57), a measure of the number of jobs in an area divided by the resident population aged 16-64. A job density of 1.0 means that there's a job for every resident aged 16-64.

If you have some experience with JavaScript this part will be way easier. Be wary that the code is written in [ES2015](https://developers.google.com/web/shows/ttt/series-2/es2015), which makes it shorter and more concise.

…

### Adding interaction
…