# Deep research guide to Irish public datasets and AI hackathon ideas

## Strategic alignment with Ireland’s AI and Digital direction

Ireland’s national AI policy framing strongly favours **people-centred, trustworthy** AI that improves public services and delivers economic and societal benefit. The “AI – Here for Good” strategy explicitly calls for a coordinated, ethical approach to public‑sector AI adoption and encourages creating “open” environments for testing AI applications, including hackathons.

The 2024 refresh of the national AI strategy groups activity into three practical strands: **building public trust in AI** (including governance, standards/certification and implementation of the EU AI Act), **leveraging AI for economic and societal benefit** (enterprise adoption and better public services), and **enablers for AI** (research ecosystem, skills, and sustainable access to compute, data and cybersecurity).

In February 2026, government published an updated National Digital & AI Strategy to 2030 (“Digital Ireland – Connecting our People, Securing our Future”). This strategy foregrounds measurable public‑service outcomes (for example, “100% of key public services digitalised by 2030”), and introduces AI‑specific public‑service capabilities and programmes (for example, an AI Advisory Unit for the public service, a National AI Fellowship programme, and a GovTech 2026 Challenge).

Taken together, a hackathon project that aligns well with these strategies will typically:
- Demonstrate **clear, practical public value** (health, housing, climate resilience, mobility, justice, etc.).
- Be **trustworthy and explainable**, with a human‑in‑the‑loop design that supports (rather than replaces) decision‑makers.
- Use **reusable public data**, ideally via stable APIs and open licences, and show strong data governance and privacy awareness.

## Dataset discovery map for Ireland

Ireland has a relatively unusual advantage for a hackathon: there isn’t just one open data portal—there is a **network of sectoral portals** (health, housing/planning, agriculture, geospatial, transport, companies, finance, etc.), many using common cataloguing patterns and machine‑readable formats.

The table below prioritises dataset sources that are (a) reputable/authoritative, (b) broad or high‑impact, and (c) realistically usable within hackathon constraints.

| Where to look | What you can get (typical examples) | Why it’s hackathon-friendly |
|---|---|---|
| Ireland's Open Data Portal | Cross‑government datasets across environment, transport, society, economy, etc.; also many “featured/high value” datasets and APIs; CKAN-based API access for catalog/search.  | Largest “one stop” catalogue; consistent metadata; many datasets are CC BY 4.0 or similar open licences.  |
| Central Statistics Office (PxStat / data portal) | Official statistics with a REST API and multiple formats (including JSON-stat, PX, CSV/XLSX); broad thematic coverage (economy, society, environment, justice).  | Official, well-documented, machine-readable; strong for modelling trends, forecasting, and benchmarking local outcomes.  |
| GeoHive | National geospatial data discovery and access, built to provide authoritative geospatial layers and apps.  | Geospatial join layers are the “glue” for cross-domain projects (linking environment, health access, housing, transport).  |
| Tailte Éireann (open geospatial + valuation) | National mapping and surveying infrastructure plus property valuation services; includes real-time valuation APIs and multiple “high value dataset” layers (e.g., land cover, buildings, water features).  | High-quality national basemaps for features/buildings/land cover (great for spatial AI); valuation data for economic/urban analytics.  |
| Environmental Protection Agency developer resources | Environmental open data APIs (bathing water, radiation monitoring, WFD, licensing/enforcement, etc.) plus mapping services via geoportal.  | Clear API endpoints and nationally relevant topics (water quality, compliance, environment risk).  |
| Met Éireann open data | Weather forecast API and extensive historical/current observations (incl. warnings, radar and climate products published under open licences, with some custom licensing for certain live forecast data).  | Key “exogenous variable” for floods, health demand, transport reliability, agriculture, renewable energy forecasting.  |
| Department of Housing, Local Government and Heritage open data | Departmental open data portal (hundreds of datasets), including merged local-authority planning registers and building-control related datasets.  | Planning pipelines and housing delivery indicators are perfect for predictive analytics and decision support.  |
| Teagasc – Agriculture and Food Development Authority open data | Research datasets across animal/grassland, crops/environment/land use, food, etc.  | Ready-made research datasets suitable for modelling, forecasting and explainable agritech prototypes.  |
| Department of Agriculture, Food and the Marine open data | Departmental portal cataloguing datasets and geospatial layers; includes geospatial APIs for farm/environment programmes (example: water quality review implementation map with a geo API).  | Strong for climate/agriculture interactions and spatial targeting (catchments, compliance, interventions).  |
| Health Service Executive datasets + performance pages | Health datasets published to the national portal; separate public pages for activity/performance including waiting lists and waiting-time information.  | High-impact public-service domain; rich opportunities for forecasting, triage decision support, and service navigation.  |
| National Treatment Purchase Fund open data | Downloadable waiting list datasets (inpatient/outpatient procedures, legacy data back to 2020).  | Clean, regular reporting; ideal for time-series analysis, queueing models and fairness/variation analysis.  |
| Tusla data catalogue | Large performance-metrics catalogue for child protection/welfare activity (JSON/CSV resources commonly published per year).  | A high-impact social domain with consistent KPI-style datasets; suited to dashboards + early warning analytics (careful governance required).  |
| National Transport Authority developer portal + GTFS | GTFS schedules and GTFS‑Realtime information (service disruptions, vehicle locations, arrival predictions) via developer portal; GTFS datasets also appear on the national portal.  | Real-time + scheduled feeds enable routing, reliability modelling, accessibility tools and urban analytics.  |
| Transport Infrastructure Ireland open data | Dedicated open data portal, traffic counts, and guidance for accessing raw/aggregated traffic counter data (CC BY 4.0 unless otherwise stated).  | High-resolution mobility data enables congestion/incident detection, emissions proxies, and safety analytics.  |
| Sustainable Energy Authority of Ireland energy + BER data | Energy data portal and downloadable energy statistics; BER research tool provides statistical BER outputs; transaction-level BER access can be restricted and treated as personal data.  | Strong for retrofit targeting, fuel poverty proxies, and energy transition dashboards.  |
| EirGrid operational grid data | Real-time system info and quarterly system data via dashboards/reports (demand, fuel mix, renewables, etc.).  | Enables forecasting and optimisation problems—especially when combined with weather and mobility.  |
| Office of Public Works flood + hydrometric data | Real-time water level datasets published via the national portal; dedicated API guidance and flood spatial data catalogue.  | Core for flood forecasting/alerting, resilience analytics, and climate adaptation tools.  |
| Uisce Éireann open data | Open data pages including water supply zones; publishes policy intent around open formats, open standards and (where possible) real-time/API availability.  | Useful for water-quality/compliance visualisations and network resilience tools when paired with EPA/OPW layers.  |
| Marine Institute marine data services | Marine data catalogues and an ERDDAP server supporting multiple output formats and programmatic data access.  | Great for ocean/climate, fisheries and coastal resilience models with map-ready outputs.  |
| Geological Survey Ireland data and maps | Downloadable datasets + online viewers + metadata + web services across groundwater, geohazards, minerals, marine geology, etc.  | High-value layers for flood risk, groundwater vulnerability, construction risk, and environmental assessment tooling.  |
| Central Bank of Ireland open data portal | Open data portal for Irish financial statistics, with dataset browsing and API access.  | Excellent for macro/fintech analytics, housing finance contexts, and economic indicators.  |
| Companies Registration Office open data | Open data portal for company records and financial statements; separate “Open Services” API for programmatic access.  | Enables SME ecosystem intelligence, sector clustering, survival analysis and regional economic mapping.  |
| Office of Government Procurement open procurement data | Open datasets extracted from the national tendering platform (tender notices, awards, supplier info) published under open data initiatives.  | Strong for transparency tools, anomaly detection, supplier discovery and value-for-money analytics.  |
| Houses of the Oireachtas open data APIs | APIs covering parliamentary datasets (debates, divisions/votes, parliamentary questions, etc.).  | Ideal for civic AI, policy discovery, summarisation and follow-the-money/commitments tracking (with transparency).  |
| Courts Service open data portal | Courts open data portal making annual report datasets available in machine-readable formats.  | Enables justice-system capacity analytics, throughput/backlog modelling, and public-facing explainers.  |
| An Garda Síochána statistics + CSO recorded crime | Garda operational statistics pages; official recorded crime statistics produced by CSO from Garda-recorded data.  | Supports safety analysis, prevention planning and evaluation of interventions (be mindful of data limitations).  |
| Road Safety Authority collision statistics | Collision statistics reporting remit; collision data also appears through official statistics tables (e.g., traffic collisions and casualties).  | A proven area for hotspot modelling, safer routing, and infrastructure prioritisation tools.  |
| Pobal deprivation & community open data | Deprivation index outputs derived from Census data and published as open datasets (including newer Census-based editions).  | Crucial equity lens for targeting interventions (retrofit, transport access, health access, digital inclusion).  |
| Higher Education Authority student/graduate data | Downloadable higher education student and graduate data from the HEA student record system.  | Great for skills pipeline analytics aligned to “Empower” goals of digital/AI skills and labour-market needs.  |
| Department of Social Protection statistics & datasets | Datasets on recipients/beneficiaries by scheme; official quarterly statistics with downloadable open data breakdowns (age/sex/county/nationality).  | Supports poverty/vulnerability analytics and service design—especially when linked to geography.  |
| Smart Dublin regional open data | Dublin-region open data portal with hundreds of datasets across transport, environment, planning, community amenities, etc.  | High-resolution local “city ops” datasets; ideal for quick prototypes and map-based user experiences.  |
| Public Service Data Catalogue | A catalogue describing wide-ranging public-service datasets (including personal/business/sensitive/spatial), with request workflows for protected datasets.  | Useful for ideation and future partnerships when open data is insufficient; clarifies data ownership and request paths.  |
| data.europa.eu | EU portal providing access to open data from EU, national, regional/local and geodata portals; replaces the former EU Open Data Portal and European Data Portal.  | Useful for pan‑European comparators, satellite/environment layers, and benchmarking Irish indicators.  |

## Dataset catalogue by domain

This section goes deeper: it names **dataset families** (not just portals) that are likely to inspire impactful, feasible hackathon builds. Where possible, it highlights datasets that are (a) open/licensed for reuse, (b) available as API/structured formats, and (c) linkable via geography and time.

**Health and care (service access, demand, performance, equity)**
Health datasets in Ireland span open performance reporting, open lists (e.g., service directories), and more restricted clinical datasets. The most hackathon-ready tend to be **aggregated operational metrics**.

- Public-facing planned care access data includes national waiting list views and breakdowns by hospital/specialty, published as part of health service performance reporting.
- Waiting list datasets are also available as downloadable “open data waiting list reports” via the NTPF, including inpatient and outpatient procedure datasets and legacy data back to 2020.
- The HSE publishes datasets through the national portal, enabling smaller-scale health analytics and integration prototypes.
- Child and family services metrics can be sourced from Tusla’s catalogue of performance datasets (often structured as JSON/CSV resources per year).
- For ideation beyond what is openly downloadable, the Public Service Data Catalogue documents health-related collections (including protected data), with request workflows.

**Housing and the built environment (planning pipelines, delivery, retrofit, affordability)**
Housing is unusually rich in Ireland because planning and building control data can be spatially enabled, linkable, and high frequency.

- The housing department’s open data portal includes merged planning registers from participating local authorities, with formats ranging from CSV/GeoJSON to ArcGIS GeoServices REST APIs; it also includes commencement notices and other planning/building control related datasets.
- The National Planning Geospatial Data Hub provides planning-focused datasets and map viewers (including a national planning application database map viewer referenced by the hub’s “National Planning Datasets” page).
- Property market data: the Residential Property Price Register includes date of sale, price and address for residential properties purchased since 2010 (as declared for stamp duty purposes).
- Retrofit/energy: the BER research tool provides statistical access to building energy rating information, and the BER system is explicitly used to analyse dwellings’ energy ratings and characteristics.
  - Note that more granular BER assessment data can be treated as personal data and may have restricted access paths requiring consent/eligibility, so it’s essential to stay within openly reusable outputs for a hackathon.
- Construction compliance: the Building Control Data Portal provides access to data submitted through the Building Control Management System (commencement notices, fire/disability access cert applications, compliance certs).
- Land and property context: Tailte Éireann provides real-time valuation services via a valuation API and publishes a broad set of national geospatial layers (including “high value datasets” such as buildings and land cover).

**Environment, climate, water and land (risk, compliance, nature, adaptation)**
This domain is especially well aligned with “transformative innovation” because datasets capture hazards (flooding), exposures (land use/cover), and outcomes (water/air quality).

- The EPA provides environmental open data APIs—including bathing water, WFD datasets, radiation monitoring, and enforcement/licensing-related access portals—explicitly intended for developer use over HTTP.
- Examples of API-accessible environmental programmes include WFD open data (catchments, waterbodies, monitoring programmes) and bathing water endpoints (locations, measurements, alerts).
- EPA mapping and download infrastructure includes an EPA geoportal with WMS/WFS and ArcGIS REST services, supporting GIS-first prototypes.
- Flood and hydrology: OPW water level datasets are published openly (last five weeks in the national portal resource), and the water level portal offers an API with near-real-time updates (and rate‑limit guidance).
- Flood spatial layers: OPW’s flood information portal includes an “Open Spatial Data Catalogue” for flood risk management and coastal change datasets.
- Weather and climate: Met Éireann publishes open datasets and a forecast API (point forecasts), including open licensing statements for many datasets while noting a custom licence for certain live forecast data.
- National emissions: the EPA publishes national greenhouse gas inventory data and projections pages, including “latest emissions data” summaries and related publications.
- Land cover: the National Land Cover Map (2018-based) is described as mapping what is physically present on the Earth’s surface and is available as an open dataset/service, produced by Tailte Éireann in partnership with the EPA.
- Water utilities: Uisce Éireann publishes an open data page including water supply zones, framed around water quality reporting/compliance.
- Agriculture-environment interfaces: the agriculture department’s portal includes spatial datasets with geo APIs (example: a water quality review implementation map with an API access URL and OpenAPI spec).

**Transport, mobility and road safety (reliability, congestion, accessibility, decarbonisation)**
Transport data is high-frequency, operationally relevant, and ideal for human-centred “decision support” AI.

- Public transport schedules and real-time disruption/vehicle/arrival data are available via the NTA developer portal through GTFS and GTFS‑Realtime specifications, with fair-usage constraints and shifting API versions over time.
- On the national portal, NTA GTFS datasets are described as ZIP collections of text files following the GTFS schedule specification.
- Road network and traffic: TII publishes a dedicated open data portal (CC BY 4.0 unless indicated) and detailed traffic counts. It also provides guidance on accessing raw and aggregated traffic counter datasets.
- Local city operations: Smart Dublin’s portal hosts hundreds of datasets, including APIs for bike share and pedestrian/cycle counters, and many GIS layers suitable for urban “digital twin” prototypes.
- Road safety: the Road Safety Authority reports collision data (sourced from An Garda Síochána) and the national portal hosts collision-related official statistics tables.

**Economy, enterprise and public-sector operations (transparency, productivity, ecosystem intelligence)**
These datasets are strong for the hackathon theme because they let you build AI that **augments human decision-making** in policy, enterprise and oversight.

- Financial statistics: the Central Bank’s open data portal publishes datasets across banking, payments, reserves, etc., and explicitly provides API access via its registry.
- Companies and financial filings: the CRO open data portal publishes company records and financial statements; it also provides programmatic “Open Services” access for integrating company/submission data into applications.
- Public procurement transparency: the Office of Government Procurement provides open procurement datasets from the national tendering platform, including tender notices and award information, with defined coverage windows and update frequency notes.
- Public expenditure: the Public Expenditure Databank provides access to voted public expenditure data (with tooling to create custom tables/spreadsheets); public-facing visualisations are also available through government “where your money goes” dashboards.
- Civic oversight and legislative text: parliamentary open data APIs provide datasets relating to debates, votes/divisions and parliamentary questions.

**Justice, education and social wellbeing (system capacity, outcomes, inequality lenses)**
These are compelling for “human intelligence driving innovation” because they involve complex systems where AI can surface patterns and trade-offs—but should remain support tools.

- Courts: a dedicated courts data portal publishes annual report datasets in machine-readable formats and explains that they should be read with annual report context.
- Crime and safety: the CSO produces quarterly recorded crime statistics describing volume/type of crimes recorded by An Garda Síochána; multiple crime datasets exist in open formats through the national portal.
- Education: the HEA provides downloadable student and graduate data sourced from annual administrative returns; the Department of Education and Youth publishes school datasets and education statistics resources.
- Social protection: the Department of Social Protection publishes datasets on welfare recipients by scheme and open quarterly statistical breakdowns.
- Deprivation and equity: the Pobal HP Deprivation Index uses Census data to analyse multiple measures of disadvantage and is available as open data (including Census‑2022-based editions).
- Research-only datasets: the Irish Social Science Data Archive maintains a catalogue of datasets accessible via request processes (useful for longer-term research projects, often not hackathon‑immediate).

## Cross-linking datasets for more ambitious AI projects

High-impact hackathon prototypes usually “level up” when they connect multiple datasets around shared keys. In Ireland, the most practical linkage strategy is **geography-first**.

**Use national statistical geographies as your join spine**
Census small areas are designed as the lowest level for statistical dissemination and typically comprise roughly 80–120 dwellings; they nest within electoral divisions.
CSO small area population statistics can be downloaded in CSV, and the corresponding boundary files are explicitly linked via Tailte Éireann’s open data portal.

This enables a powerful pattern:
- join *any* point/polygon dataset (planning applications, traffic sites, air monitors, flood zones) to small areas/EDs,
- enrich with Census indicators (population, age distribution, housing stock),
- add deprivation scores as an equity lens,
- produce ranked intervention lists or scenario dashboards.

**Exploit “high value datasets” and national baselayers for spatial AI**
Tailte Éireann publishes national high-value layers such as the 2018 national land cover map (36 land classifications) and other feature layers (e.g., buildings).
The EPA frames the land cover map as a significant improvement in land evidence with uses across water, climate, air and biodiversity assessments.

**Treat “real-time” as a modelling asset**
If your project involves forecasting, anomaly detection or operational decisions, prioritise real-time or near-real-time sources such as:
- OPW real-time water levels (updated frequently; station data added around 15-minute cadence with API rate-limit guidance).
- Met Éireann forecast API and live warnings.
- NTA GTFS‑Realtime feeds (subject to fair usage and evolving APIs).
- EirGrid operational data via dashboards/reports (system demand and quarter-hour system datasets).

**Be explicit about what is open vs request‑only**
The Public Service Data Catalogue documents datasets that may include personal or sensitive personal data and supports dataset request workflows. This is ideal for ideation, but most hackathons will need to stay with openly downloadable, non-personal datasets.
Similarly, some energy and health datasets have restricted access pathways because they can identify individuals (for example, BER assessment data being treated as personal data).

## AI project idea portfolio inspired by these datasets

The ideas below are intentionally framed as **human-centred, decision-support** tools (human intelligence steering transformative innovation), and map naturally to Ireland’s AI priorities: trustworthy AI, public-service improvement, economic and societal benefit, and strong enablers (data/skills/security).

### Public services and health

**Waiting List Flow Simulator**
Use open waiting list datasets to build a queueing/forecast model that simulates “what-if” scenarios (e.g., added capacity, weekend clinics), with uncertainty bands and explanations. Pair with a clinician/manager-friendly interface and an “assumptions editor” so human expertise can adjust service rules. Ground in NTPF open data and public waiting list reporting.

**Care Access Equity Lens**
Combine waiting list indicators with deprivation index scores and Census geographies to surface areas where long waits and disadvantage co-occur, and propose targeted outreach or capacity rebalancing. This is explicitly aligned with “people-centred” outcomes and can be presented as an explainable prioritisation map.

**Service Navigation Copilot for Public Health Pages**
Create a retrieval-based assistant that helps users find the right waiting list/wait time information and explains definitions (“inpatient vs day case”, how estimates are calculated). Keep it grounded on public performance pages (no hallucinations), and show citations to the official content in-app.

**Child Protection Capacity Early Warning Dashboard**
Use Tusla performance metrics (open cases, allocations, waiting allocation) to detect sudden shifts by area/time, and generate “investigation prompts” for managers (not automated decisions). Emphasise human review and transparent thresholds.

### Housing, planning and retrofit

**Planning Pipeline Forecaster**
Use merged planning application datasets to forecast likely approvals/commencements by area and time window; include interpretable features (application type, area trends, seasonal effects). Present the model as a decision-support tool for infrastructure planning and housing delivery monitoring.

**Commencement-to-Completion Risk Scoring**
Use building control milestone datasets (commencements, compliance certificates) to model which project types/areas are at higher risk of delay or non-completion, surfacing where human follow-up could prevent bottlenecks.

**Retrofit Prioritisation with Fairness Controls**
Use BER statistical outputs plus small-area deprivation scores to propose a retrofit priority list that explicitly balances (i) carbon reduction potential and (ii) equity/fuel poverty proxies (without needing personal BER-level data).

**Local “Heat Loss” Risk Map (Explainable)**
Build an area-level model estimating probable poor energy performance using open BER statistics + building age proxies (where available) + deprivation + housing density. Output should be explainable (“top drivers”), and designed for local authority retrofit programmes.

**Property Market Transparency Toolkit**
Use the property price register plus official price indices to build a “neighbourhood change” dashboard (price dispersion, volatility, turnover), while highlighting the limitations that the register is not itself a price index.

### Climate, water, flooding and environment

**Flood Nowcast + Human Validation Loop**
Fuse OPW real-time water levels with Met Éireann forecasts to create a short-horizon nowcast of flood risk by catchment. Add a human validation workflow (local authority engineers/community observers can annotate) to improve model performance and trust.

**Community “Flood Readiness” Recommender**
Use flood spatial layers and hydrometric data to recommend community preparedness actions, signage locations, and prioritised inspections. Keep outputs as recommendations with uncertainty and links back to official flood information.

**Water Quality Risk Explorer**
Combine EPA catchments/WFD datasets with land cover and agriculture programme layers to explain drivers of waterbody status and suggest where monitoring or interventions may help. Emphasise interpretability and provenance (all layers backed by authoritative sources).

**Beach Safety Prediction (Bathing Water)**
Use bathing water measurements/alerts and weather patterns to forecast short-term “risk of poor classification” days, with transparent features and public-friendly health guidance.

**Air Quality Micro-intervention Planner**
Use air monitoring site locations and local traffic/transport proxies to identify where and when PM/NO₂ spikes likely occur, and propose targeted measures (street sweeping, anti-idling, diversion messaging). For Dublin-scale prototypes, Smart Dublin and city noise/air APIs can accelerate delivery.

### Transport, mobility and safety

**Public Transport Reliability & “Missed Connection” Predictor**
Use GTFS schedules + GTFS‑Realtime to learn where delays cascade into missed transfers. Output “reliability scores” and suggested timetable padding or passenger guidance messages. Include a “planner mode” for human transport planners to test changes.

**Accessible Journey Planner (Mobility Impairment Focus)**
Combine schedules, real-time updates, and accessibility attributes (where available) to build a planner that prioritises step-free routes, wider transfer times, and disruption-aware alternatives. The “human intelligence” element is letting users set constraints and feedback on route quality.

**Traffic Counter Anomaly Detector for Incident Response**
Use TII traffic counter series to detect sudden drops/spikes indicative of incidents, closures or sensor faults. Combine with weather and planned events to reduce false positives.

**Road Safety Hotspot Prioritiser**
Fuse collision statistics with traffic volumes and road network features to highlight high-risk segments and rank interventions. Use an explainable model so engineers can validate and adapt.

**Active Travel Opportunity Finder**
Use city cycle/pedestrian counts, amenity locations, and deprivation indices to identify where new safe cycling/pedestrian infrastructure could deliver the biggest inclusion benefits.

### Energy and grid transition

**Renewables Output Forecaster for Community Energy**
Use EirGrid renewable and system demand datasets with weather forecasts to forecast near-term renewable contribution; present outputs as an educational and operational tool for community energy groups.

**Grid Stress Early Warning (Public Explainer + Operator Mode)**
Combine grid demand, weather extremes, and mobility signals to explain “why the grid is under pressure today” with transparent drivers. Two interfaces: public education + operator exploration.

### Economy, enterprise and civic transparency

**Procurement Fairness & Competition Monitor**
Use open procurement datasets to flag unusual patterns (single-bid tenders, repeated winners, timeframe anomalies). Output is an analyst‑in‑the‑loop triage dashboard with “why flagged” explanations.

**SME Survival and Growth Signals**
Use CRO company records and financial statements (where available), plus geographic context, to build sectoral dashboards that identify regions or sectors with rising dissolutions or falling filings. Focus on aggregate signals rather than individual scoring as “truth”.

**Parliamentary Question Theme Tracker**
Use Oireachtas APIs to cluster and track topics over time (housing, health, climate, safety), highlighting where public concerns are intensifying. Use human-in-the-loop labelling for topic names to keep clusters meaningful.

**Justice System Throughput and Backlog Explorer**
Use courts annual report datasets to model throughput vs filings and simulate how capacity changes might affect backlog. Make the assumptions explicit and allow scenario editing by policy users.

### Quickfire additional ideas (high feasibility)

These are narrower, but often ideal for hackathon timeboxes because they can be delivered as one clean pipeline + one UI.

- **“Census + Everything” join toolkit**: a reusable script/notebook that spatially joins any dataset to Small Areas/EDs and outputs a standard analytics table for downstream modelling.
- **Climate risk lens for planning applications**: overlay planning applications with flood layers and land cover to produce a “risk context” card that planners can use in assessment.
- **Tourism demand & event capacity forecaster** using open tourism events/attractions/accommodation registers, potentially to better distribute visitors and reduce congestion impacts.
- **Water supply zone compliance explainer**: an interactive map of supply zones with plain-language summaries and links to environmental compliance context (EPA + water utility open data).
- **Local authority “digital twin starter pack”** for Dublin: unify Smart Dublin datasets (signals, cycle counts, amenities) into a single queryable spatial database with a lightweight API.

## Governance, ethics and hackathon delivery tips

Ireland’s AI policy directions consistently emphasise **trust, transparency and rights-respecting AI**. The national AI strategy refresh explicitly links trust-building to governance mechanisms, standards/certification and EU AI Act implementation.

For a hackathon entry, the practical translation is:

**Stay in “decision support”, not automated decisioning**
For public-service domains (health, justice, welfare), design outputs as recommendations or insights with clear confidence/uncertainty, and leave final decisions to humans. This matches Ireland’s emphasis on trustworthy, person-centred AI.

**Demonstrate provenance and reduce hallucination risk**
If you use generative AI, restrict it to retrieval/grounded flows and cite official sources and datasets inside the app. This is especially aligned with building public trust and transparency goals.

**Be explicit about licensing and reuse**
Ireland’s open data ecosystem is shaped by the EU Open Data Directive (transposed into Irish law in 2021) and many datasets are published for free reuse under open licences.

**Avoid restricted personal data unless the organisers provide it**
Some datasets (e.g., transaction/assessment-level building energy data, or clinical datasets) can qualify as personal data and require agreements/consent or controlled access. A hackathon project can still be impactful using aggregated/open alternatives.

**Map your project narrative to the 2030 “Apply / Grow / Invest / Lead / Empower” ambitions**
Even a small prototype can align if you show: a service improvement (“Apply”), an enterprise/vibrant ecosystem angle (“Grow”), good security/data handling (“Invest”), compliance/trust (“Lead”), and user literacy/empowerment (“Empower”).
