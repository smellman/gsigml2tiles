# gsigml2tiles

Convert gsi gml dem to tiles.

# Usage

```bash
docker build -t gsigml2tiles .
docker run -u `id -u`:`id -g` -v /path/to/gml:/gml -v /path/to/output:/output gsigml2tiles
```