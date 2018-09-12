# journocoders-geogrid

In this tutorial we will learn to make hexagonal grids using the [geogrid](https://github.com/jbaileyh/geogrid) package and use the resulting geometry with D3. This is a simplified version of the author's own reference, aimed at getting the spatial data out of R.

There are several ways to transform geographic data to hexagons. This method is intended for creating your own cartography from a set of geographic features. This produces a different output than libraries like [d3-hexbin](https://github.com/d3/d3-hexbin) or [d3-hexgrid](https://github.com/larsvers/d3-hexgrid), as those bin points in a fixed area for density-graduated data visualisations.

## Installing R

First you need to install R. If you're using macOS you can simply use [homebrew](https://brew.sh) with `brew install R`. If you use GNU/Linux, please refer to your package manager. If you use Windows you can [install R through CRAN](https://cran.rstudio.com/).

Once you have R installed please do get [RStudio](https://www.rstudio.com/products/rstudio/download/#download). It is a comfortable environment to write R code, with inline documentation and examples.

### Installing geogrid

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

### Installing geojsonio

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

Now that we have the geometry, let the fun begin. To view our graphic locally and be able to request data we need to create a local development server. It sounds scary but it isn't! You can install [served](http://enjalot.github.io/served/), and drag & drop this folder inside the app to work with the map.

After your localhost is available you can open the same folder with your code editor of choice and go to `index.html`.

### Rendering the map

We will visualise [job density](https://www.nomisweb.co.uk/query/construct/summary.asp?mode=construct&version=0&dataset=57), a measure of the number of jobs in an area divided by the resident population aged 16-64. A job density of 1.0 means that there's a job for every resident aged 16-64.

If you have some experience with JavaScript this part will be way easier. Be wary that the code is written in [ES2015](https://developers.google.com/web/shows/ttt/series-2/es2015).

There's two HTML files. The one we will use, `index.html` is heavily commented and contains a basic skeleton with a container. The other, `index-completed.html`, has the finished map with minimal annotation.

I won't reference basic HTML or JavaScript because it would make the tutorial too long. You can do a [MDN guide](https://developer.mozilla.org/en-US/docs/Learn/HTML) if you're completely lost.

Open `index.html` with your browser of choice. If you open the DevTools you'll see an empty SVG element. This is where we will draw the map. I've already added the code that renders that container, you don't need to change that.

Go to line 44 and think about geographic data for a moment. As you may know, all maps need a [projection](https://www.colorado.edu/geography/gcraft/notes/mapproj/mapproj_f.html). In this case we are slightly lucky. This data is already on planar geometry so we will use D3's [geoIdentity](https://github.com/d3/d3-geo#geoIdentity) function.

```javascript
const projection = d3
  .geoIdentity()
  .reflectY(true) // see https://github.com/d3/d3-geo#identity_reflectY
```

Now that we have a projection we are quite close to have something on screen. Although it may seem surprising, D3's geo functions are powerful and at the same time, quick to write.

You can go inside the `ready` function, here we have the data already loaded. You can create a [TopoJSON](https://github.com/topojson/topojson-client) object (a compressed form of GeoJSON).

```javascript
const feature = topojson.feature(la, la.objects.local_authorities);
```

Each TopoJSON can have multiple features inside so we need to specify one. You can use a website like [mapshaper](http://mapshaper.org) (referenced earlier) to inspect your geodata. In our case there's only one called `local_authorities`.

We have a projection and a TopoJSON object, let's render those objects to the screen. For that there's the `d3.geoPath` function, that transforms coordinates to SVG.

```javascript
const path = d3
  .geoPath()
  .projection(projection)
```

And now let's try to draw something to screen!

```javascript
svg.append('path') // SVG complex figures are created with this element
  .datum(feature) // Attach our TopoJSON data to the SVG
  .attr('d', path) // This attribute holds the raw polygon information
```

Oops... Nothing. Not too fast. When this happens your first reaction should be opening the DevTools. There's always something you can inspect there.

![Nada](https://user-images.githubusercontent.com/1236790/44960664-650a5380-aefb-11e8-86bb-8835e6344778.png)

If you hover the mouse over the `path` element you can see that it seems to be located way outside of our screen. What could be causing this?

If you think about it for a bit, you'll realise that we haven't told D3 *where* our geographic data is on the globe. This is very **important**. We need to translate and center the map.

If you look over the [d3-geo documentation](https://github.com/d3/d3-geo#projection_fitSize) you'll see something called `fitSize`. This handy function will translate and center our map automagically if we pass it our object and the width and height.

```javascript
projection.fitSize([width, height], feature);
```

If you add this code after we declare the `feature` variable you'll hopefully see the map on screen. Here's the code of this part so far

```javascript
// Create our topojson object
const feature = topojson.feature(la, la.objects.local_authorities);

// Fit our projection
projection.fitSize([width, height], feature);

// You need a path generator to render the map
const path = d3
  .geoPath()
  .projection(projection);

// At last! Here you attach the map to our SVG
svg.append('path')
  .datum(feature)
  .attr('d', path);
```

However, if you pass the mouse over it something strange happens, the entire map turns red! Christmas is not here yet so let's change that.

The important bit is inside that esoteric `datum` instruction. The way D3 works is by attaching nodes to the DOM with our data. If you read the code you'll notice that we have only created *one* path. To be able to mouseover through every individual authority we need to find a way to render all of them separately.

This is where D3 shines, its core functionality. The [data join](https://bost.ocks.org/mike/join/). Don't fear though, it's less painful than you think. We only need to add or modify **three** lines.

```javascript
svg.selectAll('path') // Select our desired target elements
  .data(feature.features) // Pass every feature, not just one!
  .enter() // Start the looping, everything from here will be repeated for each data point
  .append('path')
  .attr('d', path);
```

Reload the page and you'll see all the authorities rendered in their own elements.

### Visualising data

…

### Adding interaction
…