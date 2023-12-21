# Map Source & Test data

## Country shapes

The [./geoJSONcountries.json][geoJSONcountries] file is a concatenation of the
GeoJSON country shapes provided by [_digitalki_](https://digitalki.net/2021/03/26/geojson-country-boundaries-data-for-all/)
(all world countries as of 2021). Some attributes were renamed:

* `ADMIN` => `country`
* `ISO_A3` => `ISO3166alpha3`