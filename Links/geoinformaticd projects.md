# 5 Geoinformatics Projects I'd Build If I Were Serious About Getting Hired

> NDVI maps of your hometown are not portfolio projects.
> These five tackle real climate problems (floods, heat, drought, air and access) with Python, R and GeoAI, and each one ends in a decision someone can act on.

**Pick ONE. Build it end to end. Ship a map people can use.**

Star this repo so you can find it again.

---


| # | Project | Level | Language | Core skill |
|---|---------|-------|----------|------------|
| 1 | [Flood Mapping with SAR + Deep Learning](#1-flood-mapping-with-sar--deep-learning) | Advanced | Python · GeoAI | Semantic segmentation on radar |
| 2 | [Urban Heat Risk](#2-urban-heat-risk) | Intermediate | Python · Earth Engine | Raster + census fusion, spatial ML |
| 3 | [Drought & Crop Stress Early Warning](#3-drought--crop-stress-early-warning) | Int. to Adv. | R · GeoAI | Satellite image time series |
| 4 | [Air Pollution Exposure](#4-air-pollution-exposure) | Int. to Adv. | R | Downscaling, regression kriging |
| 5 | [Healthcare Accessibility](#5-healthcare-accessibility) | Intermediate | Python | Network analysis, optimization |

## The 5 rules for a geo project that gets you hired

1. **A decision, not a map.** Who acts on your output, and where?
2. **Multi-source data.** Different CRS, resolutions and time stamps. Harmonizing them *is* the job.
3. **Baseline + spatial validation.** Start with a threshold or index, and use spatial cross-validation. Random splits leak through spatial autocorrelation.
4. **Deployed.** A web map, an API or a scheduled pipeline. Screenshots in a notebook don't count.
5. **Uncertainty + limitations.** Publish an uncertainty layer and say where the model breaks.

---

## 1. Flood Mapping with SAR + Deep Learning

![Flood mapping: Sentinel-1 before and during, U-Net, flood extent and impact](assets/01-flood-mapping.svg)

**What it is:** Map flood extent from Sentinel-1 radar (it works through clouds and at night), then estimate how many people and how many km of road are affected.

**The focus:** A flood mask alone helps no one. **Impact** does. Turn pixels into "12.4k people exposed, 38 km of roads cut" so responders know where to go first. Also beat a classic Otsu threshold before you reach for a U-Net.

**Build plan**
1. Baseline: Otsu thresholding on VH backscatter (dB), plus before/during change detection.
2. Train a U-Net on labeled chips with TorchGeo or `segmentation-models-pytorch`.
3. Remove false positives: mask permanent water and use terrain (HAND/slope) to drop radar shadow.
4. Evaluate IoU on hand-labeled chips from **unseen** flood events.
5. Overlay population and OSM roads and buildings, then serve it as a web map.

**Stack:** `Python` `rasterio` `xarray` `PyTorch` `TorchGeo` `geopandas` `leafmap` `FastAPI`

**Data**
- [Sen1Floods11](https://github.com/cloudtostreet/Sen1Floods11). Labeled Sentinel-1/2 flood chips for training and testing.
- [Copernicus Data Space](https://dataspace.copernicus.eu/). Fresh Sentinel-1 scenes for new events.
- [Copernicus EMS Rapid Mapping](https://rapidmapping.emergency.copernicus.eu/). Official flood maps to validate against.
- [WorldPop](https://www.worldpop.org/) + [OSM extracts (Geofabrik)](https://download.geofabrik.de/). Population and infrastructure.

**Why it matters:** Insurers, NGOs and civil protection agencies need flood extent within hours, while optical satellites are still blind under the clouds.

---

## 2. Urban Heat Risk

![Urban heat: land surface temperature grid, risk layers, priority blocks](assets/02-urban-heat.svg)

**What it is:** Find the city blocks where extreme heat meets vulnerable people, and recommend the intervention for each one.

**The focus:** The hottest block is not automatically the riskiest. **Risk = hazard × exposure × vulnerability.** Rank the blocks and attach an action to each one: trees, a cooling center or cool roofs.

**Build plan**
1. Compute land surface temperature from Landsat Collection 2 L2 (`ST_B10 × 0.00341802 + 149.0` gives Kelvin), using summer composites.
2. Add NDVI / tree cover from Sentinel-2, plus population and age from a census grid.
3. Aggregate to blocks or H3 hexes. Baseline: a weighted overlay. Then try XGBoost + SHAP.
4. Validate against weather station air temperature (and explain why LST is not air temperature).
5. Deploy an interactive map with a ranked action list.

**Stack:** `Python` `earthengine-api` `geemap` `xarray` `geopandas` `h3` `XGBoost` `SHAP` `Streamlit`

**Data**
- [Landsat 9 C2 L2 (Earth Engine)](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC09_C02_T1_L2). Surface temperature.
- [Sentinel-2 SR Harmonized (Earth Engine)](https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR_HARMONIZED). Vegetation.
- [WorldPop](https://www.worldpop.org/). Population and age structure.
- [DWD Open Data](https://opendata.dwd.de/climate_environment/CDC/). Station temperatures (Germany) for validation.

**Why it matters:** Heatwaves kill more people than any other weather hazard in Europe. Cities are writing heat action plans right now and need block-level priorities.

---

## 3. Drought & Crop Stress Early Warning

![Drought: parcel map with stress levels and NDVI anomaly during a heatwave](assets/03-drought-crop-stress.svg)

**What it is:** Detect crop stress at parcel level during droughts and heatwaves, early enough to act before harvest.

**The focus:** Compare each parcel with **its own crop's normal**, not with a global NDVI threshold. Winter wheat and maize peak at different times. Then roll parcels up to districts so the output answers a food-security question.

**Build plan**
1. Join parcel polygons and crop types with Sentinel-2 NDVI/NDMI time series (build the data cube with `sits`).
2. Build a per-crop baseline from previous years and compute z-score anomalies.
3. Add drought drivers: rainfall and soil moisture (SPI/SPEI) from CHIRPS and ERA5-Land.
4. Train a time-series classifier (Random Forest, then a temporal CNN in `sits`) for stress classes.
5. Aggregate to districts and validate against official yield statistics. Deploy a Shiny dashboard.

**Stack:** `R` `sits` `terra` `sf` `stars` `tidyverse` `Shiny` `leaflet`

**Data**
- [EuroCrops v2.0 (JRC)](https://doi.org/10.2905/b9fb9e67-78a9-4327-9d59-39a928d812d3). Harmonized IACS parcel crop types across the EU.
- [sits book](https://e-sensing.github.io/sitsbook/). Data cubes from cloud Sentinel-2 collections, with tutorials.
- [CHIRPS](https://www.chc.ucsb.edu/data/chirps) + [ERA5-Land](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land). Rainfall, temperature and soil moisture.

**Why it matters:** Ministries, insurers and agri-traders all need early yield-loss signals. Climate change makes every season less predictable.

---

## 4. Air Pollution Exposure

![Air pollution: coarse satellite NO2 downscaled to street level, schools above WHO guideline](assets/04-air-pollution.svg)

**What it is:** Downscale satellite NO₂ to street level and find which schools exceed the WHO guideline.

**The focus:** Sentinel-5P measures a **tropospheric column**, not what people breathe at street level. Calibrate it with ground stations, then add road and land-use predictors to reach about 100 m. Use **spatial cross-validation**, or your accuracy number will be fiction.

**Build plan**
1. Pull Sentinel-5P NO₂ and hourly station data, then aggregate both to annual and seasonal means.
2. Engineer land-use regression features: road length in 100/500 m buffers, land cover and ERA5 wind.
3. Baseline: ordinary kriging of the stations. Then Random Forest + residual kriging.
4. Validate with spatial block CV and map the prediction uncertainty.
5. Compute exposure at schools and hospitals, and publish a Quarto report with an interactive map.

**Stack:** `R` `sf` `terra` `gstat` `tidymodels` / `ranger` `openaq` `Quarto` `leaflet`

**Data**
- [Sentinel-5P NO₂ (Earth Engine)](https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S5P_OFFL_L3_NO2). Daily tropospheric NO₂.
- [OpenAQ API](https://docs.openaq.org/). Ground station measurements worldwide. There's also an [R client](https://cran.r-project.org/package=openaq).
- [OSM extracts (Geofabrik)](https://download.geofabrik.de/). Roads, schools and land use.

**Why it matters:** Cities design low-emission zones and school streets based on exposure maps. Health researchers need street-level estimates, not 5 km pixels.

---

## 5. Healthcare Accessibility

![Healthcare access: travel-time hex map and best location for a new clinic](assets/05-healthcare-access.svg)

**What it is:** Measure who can reach a clinic within 15 minutes by walking and public transport, then find the best location for the next one.

**The focus:** Straight-line buffers are wrong. People travel on networks and timetables. The deliverable is a **location decision**: "Site A adds 18.2k people within 15 min."

**Build plan**
1. Build a multimodal network from an OSM `.pbf` file + GTFS feeds with r5py.
2. Compute a travel-time matrix from population hexes (H3) to existing clinics.
3. Baseline: nearest-facility travel time. Then 2SFCA to account for clinic capacity versus demand.
4. Solve a maximal coverage location problem (MCLP) for candidate sites with PuLP.
5. Add an equity lens (65+ or low-income areas). Deploy as a map with a "what if" site selector.

**Stack:** `Python` `r5py` `OSMnx` `geopandas` `h3` `PuLP` `Streamlit` `pydeck`

**Data**
- [OSM extracts (Geofabrik)](https://download.geofabrik.de/). Street network and health facilities.
- [Mobility Database](https://mobilitydatabase.org/). GTFS transit feeds worldwide.
- [WorldPop](https://www.worldpop.org/). Gridded population.
- [r5py docs](https://r5py.readthedocs.io/). Routing engine and tutorials.

**Why it matters:** Health ministries, city planners and retailers all ask the same question: *where do we build next?* This is the GIS question that comes up most often in industry.

---

## ✅ Geo ship checklist

- [ ] CRS documented for every layer (and reprojected on purpose)
- [ ] Outputs saved as **Cloud Optimized GeoTIFF** and **GeoParquet**
- [ ] Spatial CV results, plus an uncertainty layer
- [ ] A live web map (Streamlit, Shiny, or leafmap on Hugging Face Spaces)
- [ ] A reproducible environment: `environment.yml` (Python) or `renv.lock` (R)
- [ ] A limitations section in the README (clouds, sensor gaps, proxy variables)
- [ ] A 60-second screen recording of the map for LinkedIn

```
project/
├── data/            # raw (git-ignored) + processed (COG, GeoParquet)
├── notebooks/       # EDA only
├── src/             # ingest, features, model, validate
├── app/             # web map / API
├── outputs/maps/
└── README.md
```

---

Building one of these? Tag **[@codewithboi](https://instagram.com/codewithboi)**. I want to see your map.
