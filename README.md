# gsigml2tiles

Convert gsi gml dem to tiles.

# Usage

```bash
docker build -t gsigml2tiles .
docker run --rm -u `id -u`:`id -g` -v /path/to/gml:/input -v $(pwd)/output:/output gsigml2tiles
```