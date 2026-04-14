# Station Geography Data Sources

## Data collection date: April 2026
## Collector: Claude (AI assistant), for Kyra Sadovi

### Notes on methodology
- Station coordinates are approximate, derived from known street intersections and web search results. They should be verified against GTFS feeds or agency GIS data before use in r5r calculations.
- Opening dates (open_date) are actual revenue service start dates from news coverage and agency press releases.
- Expected opening dates (initial_expected_open_date) are the EARLIEST publicly stated planned opening dates — the first time a specific year was projected for a given corridor, regardless of whether that projection was later revised. The goal is to identify when stakeholders would first have heard about the project and begun acting. For Sound Transit: Sound Move (1996) stations use the 10-year plan completion target of 2006; ST2 (2008) stations use the ST2 plan opening year targets; Lynnwood and Federal Way use ST2 projections as refined by the respective DEIS processes. These are approximate to month/year; exact day is 1st of the month as placeholder.
- initial_DEIS_date: dates confirmed from EPA Section 309 comment letters and EIS cover pages in 6_sources/EIS_records/ and 6_sources/fed_funding_records/. Where exact month is unknown, 1/1/YY is used as a placeholder. Remaining NAs still need primary source verification.
- Gateway tunnel project (NYC) omitted because it is infrastructure replacement with no new stations.
- Seattle West Seattle/Ballard omitted because construction has not yet begun.

---

## LA Metro (LA_Metro_stations.csv)

### D Line Extension (Purple Line)
**All sections** — initial_DEIS_date: 9/3/10 — PRIMARY SOURCE: EPA Region IX Section 309 comment letter dated October 15, 2010 (CEQ #20100353; file: `6_sources/EIS_records/LAMetro/20100353.pdf`), reviewing the Westside Subway Extension Draft EIS. The DEIS comment period ran September 3 – October 18, 2010 (web search confirmation); 9/3/10 is the Federal Register publication/comment period start date, used as the DEIS date per project methodology.

**Section 1** (Wilshire/La Brea, Wilshire/Fairfax, Wilshire/La Cienega):
- Open date: May 8, 2026 (announced) — Source: LA Metro press release via The Source (thesource.metro.net). **Not yet entered in open_date column (future date as of April 2026); update once revenue service begins.**
- Expected date: Oct 2024 — Source: FFGA signed May 2014, revenue ops scheduled Oct 2024 (transit.dot.gov FY22 project profile; Streetsblog LA). CONFIRMED by Transit Program Project Budget and Schedule Status Report, June 19, 2014 (file: `6_sources/EIS_records/LAMetro/reports_programmgmt_2014-06.pdf`), p.4: "Rev. Operation Original: Oct 2024."
- Coordinates: Wilshire/La Brea from Mapcarta/Wikipedia (34.06167, -118.34484); others estimated from Wilshire Blvd cross-street intersections

**Section 2** (Wilshire/Rodeo, Century City/Constellation):
- Open date: Not yet open, forecast spring 2027 — Source: metro.net project page
- Expected date: ~Jan 2025 — Source: FFGA signed Dec 2016 ($1.6B grant, FTA); original completion timeline approx 2024-2025 per LA Metro. NEEDS VERIFICATION.
- Coordinates: estimated from known intersection locations on Wilshire Blvd

**Section 3** (Westwood/UCLA, Westwood/VA Hospital):
- Open date: Not yet open, forecast fall 2027 — Source: metro.net project page
- Expected date: ~Jan 2026 — Source: FFGA signed March 2020 (Streetsblog LA); original timeline approx 2026. NEEDS VERIFICATION.
- Coordinates: estimated from known intersection locations

### Regional Connector (Little Tokyo/Arts District, Historic Broadway, Grand Ave Arts/Bunker Hill):
- Open date: June 16, 2023 — Source: LA Metro press release (metro.net)
- Expected date: May 29, 2021 — Source: FFGA signed Feb 2014, revenue ops scheduled May 2021 (transit.dot.gov FY18 project profile). CONFIRMED by Transit Program Project Budget and Schedule Status Report, June 19, 2014 (file: `6_sources/EIS_records/LAMetro/reports_programmgmt_2014-06.pdf`), p.5: "Rev. Operation Original: May 2021."
- initial_DEIS_date: 9/1/10 (placeholder; exact day in September 2010 not confirmed) — PRIMARY SOURCE: EPA Region IX Section 309 comment letter dated October 8, 2010 (CEQ #20100352; file: `6_sources/EIS_records/LAMetro/20100352.pdf`), reviewing the Regional Connector Corridor Project Draft EIS. DEIS published September 2010 (web search confirms 45-day comment period with public meeting September 28, 2010; EPA letter October 8, 2010 falls within that window). Exact Federal Register notice date needs confirmation.
- Coordinates: estimated from known intersection locations in Downtown LA

### K Line / Crenshaw/LAX
- Open date: Oct 7, 2022 (Expo/Crenshaw to Westchester/Veterans); June 6, 2025 (Aviation/Century and LAX/Metro Transit Center) — Source: LAist, Streetsblog LA, metro.net
- Expected date: 12/1/18 (December 2018) — PRIMARY SOURCE: Transit Program Project Budget and Schedule Status Report, June 19, 2014 (file: `6_sources/EIS_records/LAMetro/reports_programmgmt_2014-06.pdf`), p.3: "Rev. Operation Original: Dec 2018." This is earlier than the previously noted ~2019 projection from LAist/Wikipedia; the June 2014 program report confirms December 2018 as the original FFGA-era baseline. **Updated in CSV from 1/1/19 to 12/1/18 (April 2026).**
- initial_DEIS_date: 9/11/09 — PRIMARY SOURCE: EPA Region IX Section 309 comment letter dated October 26, 2009 (CEQ #20090315; file: `6_sources/EIS_records/LAMetro/20090315.doc`), reviewing the Crenshaw Transit Corridor Project Draft EIS. DEIS comment period ran September 11 – October 25, 2009 (web search confirmation via Metro Library Archives); September 11, 2009 is the publication/circulation start date.
- Coordinates: estimated from known intersection locations along Crenshaw Blvd

---

## SF Muni Central Subway (SF_Muni_Central_Subway_stations.csv)
- Open date: Jan 7, 2023 (full revenue service) — Source: SFMTA, KQED, CBS SF
- Expected date: ~Dec 2018 — Source: FFGA signed Nov 2012, originally scheduled late 2018 (CBS SF, Local News Matters, SFMTA blog)
- Coordinates: estimated from known locations along 4th Street/Stockton Street alignment

---

## VTA BART Silicon Valley Phase 1 (BART_SV_Phase1_stations.csv)

Phase 1 of the Silicon Valley Rapid Transit Corridor (SVRTC) project, also known as the Berryessa Extension, extends BART 10 miles from Warm Springs to Berryessa/North San José, with two new stations: Milpitas and Berryessa/North San José. Phase 1 broke ground in 2012 and opened for revenue service on June 13, 2020.

- Open date: June 13, 2020 — Source: BART press release (bart.gov/news, May 19, 2020), ABC7
- Coordinates: Milpitas (-121.89108, 37.41028) from SF Bay Transit / web search; Berryessa/North San José (-121.87468, 37.36847) from SF Bay Transit / web search. Should be verified against BART GTFS feed.

**`initial_expected_open_date` (both stations): 1/1/12.** The earliest publicly projected opening date for BART to Silicon Valley comes from a December 17, 2001 San Francisco Chronicle article (Michael Cabanatuan, "Transit plan a commuter's dream / 'Baby bullet' trains, a new bus terminal, BART to Silicon Valley"), which reported that "By 2012, if all goes according to plan, East Bay commuters will ride BART to their Silicon Valley jobs." This was published in connection with the Metropolitan Transportation Commission's adoption of a 25-year regional transportation spending plan. The 2004 DEIS later projected 2013 for the full BART Alternative; the 2001 projection of 2012 is earlier and is used per methodology. File: `6_sources/EIS_records/SF/Transit plan a commuter's dream _ 'Baby bullet' trains, a new bus terminal, BART to Silicon Valley.pdf`.

**`initial_DEIS_date` (both stations): 3/16/04.** PRIMARY SOURCE: Silicon Valley Rapid Transit Corridor Draft EIS/EIR (FTA and Santa Clara Valley Transportation Authority, March 2004). Cover page signed 3/2/04 (Leslie T. Rogers, FTA Regional Administrator, Region IX) and 1/27/04 (Peter M. Cipolla, VTA General Manager). The 60-day public comment period ran March 16 – May 14, 2004; 3/16/04 is the Federal Register Notice of Availability / comment period start date. The DEIS described a 16.3-mile BART extension from south of Warm Springs to Santa Clara with seven stations plus one future station: South Calaveras (Future), Montague/Capitol, Berryessa, Alum Rock, Civic Plaza/SJSU, Market Street, Diridon/Arena, and Santa Clara. Phase 1 stations correspond to Montague/Capitol (now Milpitas) and Berryessa. Files: `6_sources/EIS_records/BART/A.%20Cover%20Page%20and%20Abstract.pdf`, `6_sources/EIS_records/BART/Chapter01%20-%20Executive%20Summary.pdf`, `6_sources/EIS_records/BART/Chapter02%20-%20Introduction.pdf`.

---

## VTA BART Silicon Valley Phase 2 (BART_SV_Phase2_stations.csv)

Phase 2 of the SVRTC project extends BART approximately 6 miles from Berryessa/North San José through a subway tunnel under downtown San José to Santa Clara, with four new stations. Phase 2 is under construction; current projected opening is ~2037.

- Open date: Not yet open, targeted 2037 — Source: VTA (vtabart.org), ABC7
- Coordinates: estimated from known locations in downtown San Jose. NEEDS VERIFICATION against VTA project GIS data.

**`initial_expected_open_date` (all stations): 1/1/12.** Same source as Phase 1: the December 2001 SF Chronicle article projected BART to Silicon Valley operational "By 2012." This projection encompassed the full corridor including the downtown San José stations. The 2004 DEIS later projected 2013 for the full BART Alternative (or ~2016 for Phase 2 under a Minimum Operating Segment scenario). The FY24 FTA project profile estimated ~2030, but per methodology the earliest publicly stated projection (2012) is used. **Updated in CSV from 1/1/30 to 1/1/12 (April 2026).**

**`initial_DEIS_date` (all stations): 3/16/04.** Same 2004 DEIS as Phase 1. The Phase 2 stations correspond to 2004 DEIS stations as follows: Alum Rock (at 28th Street) → 28th Street/Little Portugal; Civic Plaza/SJSU → Downtown San Jose; Diridon/Arena → Diridon; Santa Clara → Santa Clara. Market Street station (present in the 2004 DEIS) was subsequently dropped from Phase 2 during project redesign. The station locations did not fundamentally change with the Phase 2 redesign — unlike the Central Subway case where the alignment shifted from Third Street/Kearny to Fourth/Stockton — so the 2004 DEIS is used as the initial DEIS per methodology, not the Phase 2-specific Draft SEIS/SEIR (December 28, 2016, comment period through March 6, 2017). The Final SEIS/SEIR was released February 21, 2018; Record of Decision issued June 4, 2018. **Updated in CSV from NA to 3/16/04 (April 2026).**

NOTE on project history: The original 2004 DEIS covered the full SVRTC corridor as a single project. In September 2007, FTA published a Notice of Intent to prepare a Revised EIS (Federal Register, September 21, 2007). The project was subsequently split into Phase 1 (Berryessa Extension, with its own Final EIS in 2010) and Phase 2 (Downtown San José Extension, with Draft SEIS/SEIR December 2016 and Final SEIS/SEIR February 2018).

---

## MBTA Green Line Extension (MBTA_GLX_stations.csv)
- Open date: March 21, 2022 (Lechmere, Union Square); Dec 12, 2022 (Medford branch) — Source: MBTA press releases
- Expected date: 12/31/11 — PRIMARY SOURCE: Federal Register, Vol. 59, No. 191 (October 4, 1994), pages 50495-50496 (file: `6_sources/EIS_records/MBTA/50495-50499.pdf`). Table 1 lists "Transit Project 12/31/11 ... Green Line Extension To Ball Square/Tufts University" as a Massachusetts Clean Air Act SIP commitment. This is the earliest documented projected completion date. **Updated in CSV from 12/1/21 to 12/31/11 (April 2026).**
- initial_DEIS_date: 10/4/94 — PRIMARY SOURCE: Federal Register, Vol. 59, No. 191 (October 4, 1994), pages 50495-50496 (file: `6_sources/EIS_records/MBTA/50495-50499.pdf`). EPA approval of Massachusetts SIP revision for Transit System Improvements and HOV Facilities. Used as DEIS-equivalent marker; the GLX project itself used an Environmental Assessment (EA, October 2011) with FONSI (July 2012), not a DEIS. The 1994 Federal Register is the earliest federal regulatory document establishing a projected completion date. **Updated in CSV from NA to 10/4/94 (April 2026).**
- Coordinates: estimated from known intersection locations in Somerville/Medford

---

## NYC Stations (NYC_stations.csv)

### 7 Extension (34th Street-Hudson Yards):
- Open date: Sept 13, 2015 — Source: 6sqft.com, CBS New York, Wikipedia
- Expected date: Dec 2013 — Source: original target from 2007 contract award (Wikipedia, Timeout NY)
- Coordinates: 40.75588, -74.00183 — Source: CoordinatesFinder.com, Mapcarta

### Second Avenue Subway Phase 1 (72nd, 86th, 96th Streets):
- Open date: Jan 1, 2017 — Source: MTA, numerous news outlets
- Expected date: Dec 2012 — Source: per 2005 bond issue, MTA said completion by 2012 (Wikipedia, Construction of the Second Avenue Subway)
- Coordinates: estimated from known locations on Second Avenue, Upper East Side

### Second Avenue Subway Phase 2 (106th, 116th, 125th Streets):
- Open date: Not yet open, expected Sept 2032 — Source: MTA, Governor Hochul announcement
- Coordinates: estimated from projected station locations along Second Avenue. NEEDS VERIFICATION — stations under design.

### East Side Access / Grand Central Madison:
- Open date: Jan 25, 2023 (limited service), Feb 27, 2023 (full service) — Source: MTA, Gothamist, New York YIMBY
- Expected date: ~2011 — Source: MTA officials planned completion ~2011 when construction began 2001 (Gothamist, Wikipedia)
- Coordinates: 40.75278, -73.97722 — near Grand Central Terminal

---

## Honolulu HART Skyline (Honolulu_HART_stations.csv)
- Open dates: Segment 1 June 30, 2023; Segment 2 Oct 16, 2025; Segment 3 planned 2031 — Source: honolulutransit.org, Hitachi Rail, Aloha State Daily
- Expected date: 2020 for full system — Source: original plan was full 20-mile system open by 2020 (Progressive Railroading, Construction Dive, Real Hawaii)
- Coordinates: approximate, based on known station locations along guideway. Official GIS data available at Hawaii State Geoportal (geoportal.hawaii.gov) and Honolulu Open Data (honolulu-cchnl.opendata.arcgis.com). RECOMMEND VERIFYING with these datasets.

---

## Miami-Dade Metrorail MIA Extension (Miami_Metrorail_stations.csv)
- Open date: July 28, 2012 — Source: Miami-Dade County transit releases, Metro Atlantic blog
- Expected date: 1/1/03 (placeholder; Year 8 of the MIC phasing plan = calendar year 2003) — PRIMARY SOURCE: Miami Intermodal Center Policy and Technical Steering Committees' Recommendation Report (MIS/DEIS), February 1996 (file: `6_sources/EIS_records/Miami/intermodal-center-recommendation-report-1996-02.pdf`). Table 6 (Conceptual Project Construction Phasing Plan) lists the MIC/MIA Connector — including MIC and MIA station completion — for project Years 5–8. Table 8 (Annual Capital Outlays & Inflation Factors) maps Year 1 = 1996, Year 5 = 2000, Year 8 = 2003. The expected opening was therefore approximately 2003, representing an actual delay of ~9.5 years from initial projection. The previously recorded expected date of ~April 2012 (spring 2012 from Progressive Railroading/Railway Technology) was a much later re-projection and is superseded by this earlier source per project methodology.
- Coordinates: coordinates updated from GIS verification; original estimate was 25.7910, -80.2550
- initial_DEIS_date: 11/3/95 — PRIMARY SOURCE: Miami Intermodal Center MIS/DEIS, February 1996 (file: `6_sources/EIS_records/Miami/intermodal-center-recommendation-report-1996-02.pdf`), Section 1.1.3: "Public involvement and review of the MIS/DEIS culminated with a notice of availability published in the Federal Register legally announcing a 45-day public comment period." The 45-day comment period ran November 3 – December 18, 1995; November 3, 1995 is the Federal Register notice of availability date. NOTE: A later, separate scoping notice (NOI) for the Earlington Heights Connector EIS was published April 30, 2001 (Federal Register Vol. 66, Issue 83, document 01-10670; file: `6_sources/EIS_records/Miami/01-10670.pdf`). The 1995 MIS/DEIS is used as the initial_DEIS_date per methodology (earliest DEIS-equivalent document). The 2006 SDEIS NOI for the East-West Corridor (FIU–MIC) is also on file (`6_sources/EIS_records/Miami/E6-7865.pdf`) but is a later re-scoping and is not used.

---

## Sound Transit Link (Sound_Transit_Link_stations.csv)
Replaces the earlier U_link_stations.xlsx and Sound_Transit_ULink_stations.csv with a comprehensive file covering all Link extensions.

### Roads & Transit Ballot Measure (failed, Nov 2007):
- Source: Sound Transit press release "Governor Approves Joint 'Roads & Transit' Ballot Measure Legislation" (May 14, 2007); file: `6_sources/EIS_records/SoundTransit/Governor Approves Joint "Roads & Transit" Ballot Measure Legislation _ Sound Transit.pdf`
- Context: Gov. Gregoire signed legislation on May 14, 2007 enabling the Roads & Transit measure to go to voters in November 2007. The plan proposed 50 miles of new light rail to Bellevue, Redmond, Mercer Island, Des Moines, Federal Way, Fife, Tacoma, Northgate, Shoreline, Mountlake Terrace, and Lynnwood — the same corridors that became East Link, Federal Way Link, Northgate Link, and Lynnwood Link under ST2 (2008). Roads & Transit was defeated at the November 2007 ballot. Sound Transit then placed the transit-only ST2 measure on the November 2008 ballot, which passed.
- Relevance: Confirms all major ST2 Link corridors were publicly proposed as early as May 2007. The Roads & Transit plan did not include specific projected opening dates.

### Angle Lake (1 station, opened Sept 24, 2016):
- Open date: Sept 24, 2016 — Source: Sound Transit press release, Wikipedia
- Expected date: 1/1/06 — PRIMARY SOURCE: Wikipedia (Angle Lake station article): "Sound Move…selected a station at South 200th Street in SeaTac as the southern terminus…approved by voters in November 1996 and was scheduled to open in 2006." South 200th Street / Angle Lake was the planned southern terminus of the original Sound Move Central Link system. Budget problems in 2001 truncated the line to Tukwila; airport extension eventually opened December 2009; Angle Lake itself opened September 2016 via TIGER grant acceleration (awarded December 2011, $10M allowing opening to move from 2020 to 2016). Roads & Transit (2007) included S 200th as part of a 4.3-mile extension to Highline College area (by 2021). ST2 (2008) included a further extension to Redondo/Star Lake by 2023; Angle Lake was accelerated separately using federal funds.
- initial_DEIS_date = 12/11/98 — Same original Central Link DEIS (December 1998). The full 24-mile Sound Move corridor ran from Northgate to South 200th Street.
- Coordinates: approximate (-122.29750, 47.44528), based on known station location at S 200th St & International Blvd, SeaTac. Verify against King County GIS.

### Central Link (13 stations, opened July 18 / Dec 19, 2009):
- Open date: July 18, 2009 (Westlake–Tukwila); Dec 19, 2009 (SeaTac) — Source: HistoryLink.org, Sound Transit press releases
- Expected date: 2006 — PRIMARY SOURCE: Sound Move Ten-Year Regional Transit System Plan (adopted May 31, 1996), page 6: "System completion within ten years"; pages 18, 26, 29: light rail built in three segments with the south segment first, entire system operational within ten years. Also confirmed by FTA FY2006 Annual Report on Funding Recommendations (Report FTA-TBP10-2005-1), Table 1: Central Link Initial Segment listed as existing FFGA with $500M total funding. Secondary: HistoryLink.org notes revised to 2009 after 2000 cost overrun audit.
- initial_DEIS_date = 12/11/98 — PRIMARY SOURCE: FTA FY2006 Annual Report on Funding Recommendations (file: `central_link_fedfunding.pdf`), Appendix B pp. B-49–B-50: "A Draft Environmental Impact Statement (EIS) was published in December 1998. The Final EIS was completed in November 1999." CONFIRMED by web search: the Draft EIS was publicly available December 4, 1998; notification of its issuance was published in the Federal Register on **December 11, 1998**. The December 1998 DEIS covered the full original 24-mile Central Link system from Northgate to SeaTac/Airport.
  - Tukwila Freeway Route DSEIS (supplemental): CEQ No. 000361. EPA Region 10 comment letter dated December 4, 2000 (file: `20000361.pdf` / `linktukwila.DIS.pdf`). This DSEIS evaluated an alternative Tukwila alignment; the initial DEIS date for all Central Link stations remains 12/11/98.
- Stations include 5 DSTT stations (Westlake, Symphony, Pioneer Square, Int'l District, Convention Place) that gained rail service but existed as bus stations since 1990
- Coordinates: approximate, based on known station locations along MLK Jr Way/I-5 corridor. Official GIS available from King County (rst_linkstationpoints) and Seattle GeoData (data-seattlecitygis.opendata.arcgis.com)

### University Link / U-Link (2 stations, opened March 19, 2016):
- Open date: March 19, 2016 — Source: Sound Transit press release, HistoryLink.org
- Expected date: 1/1/06 — Sound Move (1996) ten-year plan included the full North Link corridor to Northgate; the earliest publicly projected completion year for the full system was 2006. Project was completed 6 months AHEAD of its revised baseline (Sept 2016), but the initial Sound Move projection was 2006.
- initial_DEIS_date = 12/11/98 — Same original Central Link/North Link DEIS of December 1998. The North Link corridor (Downtown Seattle to University District and Northgate) was included in the original 24-mile Sound Move plan. North Link DSEIS subsequently published November 2003 (CEQ No. 030526), EPA comment letter dated January 14, 2004 (file: `centrallink_EIS.pdf`). Later supplemental EISes: Modified Montlake Addendum (Feb 2004), North Link 2005 DSEIS (Oct 2005), North Link FEIS (Apr 2006). Initial DEIS date remains 12/11/98.
- Coordinates: estimated from known locations (Capitol Hill at Broadway/John; UW at Montlake Triangle)

### Northgate Link Extension (3 stations, opened Oct 2, 2021):
- Open date: Oct 2, 2021 — Source: Sound Transit press release, King5, Seattle Times
- Expected date: 1/1/06 — Sound Move (1996) ten-year plan included Northgate as the northern terminus of the original 24-mile Central Link system. Earliest publicly projected year = 2006. ST2 (2008) plan later projected "by 2020" for Northgate; but the methodology uses the earliest projection, which is Sound Move's 2006 target.
- initial_DEIS_date = 12/11/98 — Same December 1998 Central Link/North Link DEIS. ST2 (2008) funded construction but did not trigger a new initial DEIS for this corridor.
- Coordinates: estimated from known locations

### Lynnwood Link Extension (4 stations, opened Aug 30, 2024):
- Open date: Aug 30, 2024 — Source: Sound Transit press release, Fox 13 Seattle
- Expected date: ~Jan 2023 — Source: ST2 (2008) plan projected Lynnwood by 2023; st2_plan_web.pdf p.7: "extensions to Lynnwood…scheduled to open for service by 2023." Delayed to 2024 partly due to concrete truck driver strike (The Urbanist, Trains.com).
- initial_DEIS_date = 7/1/13 — APPROXIMATE (exact day unknown; using 1st of month as placeholder). Lynnwood Link Extension DEIS was published July 2013 by Sound Transit and FTA; public comment period closed September 23, 2013. FEIS published April 2015. Source: My Edmonds News (Aug 20, 2013); Sound Transit project documents; FTA Lynnwood Link Project Profile (transit.dot.gov). Note: ST2 plan provided funding for preliminary engineering and environmental documentation northward from Northgate; the Lynnwood DEIS is a separate project-level document from the original 1998 Central Link DEIS.
- Coordinates: estimated from known locations along I-5 corridor

### East Link / 2 Line (12 stations, phased opening 2024-2026):
- Open dates: April 27, 2024 (8 stations, South Bellevue to Redmond Technology); May 10, 2025 (2 stations, Marymoor Village and Downtown Redmond); March 28, 2026 (2 stations, Judkins Park and Mercer Island — the "crosslake connection") — Source: Sound Transit press releases, Fox 13 Seattle (March 28, 2026)
- Expected date by station group (using earliest ST2 projections per methodology):
  - Judkins Park, Mercer Island, South Bellevue, East Main, Bellevue Downtown: 1/1/20 — ST2 (2008) plan (st2_plan_web.pdf): "open to Bellevue by 2020"
  - Wilburton, Spring District/120th, BelRed/130th, Overlake Village, Redmond Technology: 1/1/21 — ST2 plan: "service scheduled to start in 2021" for Overlake Transit Center area of Redmond
  - Marymoor Village, Downtown Redmond: 1/1/21 — Downtown Redmond was originally included in the ST2 (2008) ballot measure as part of the East Link project. It was subsequently deferred from construction (PE suspended 2010) due to a funding shortfall caused by the City of Bellevue's requirement for a tunneled alignment under Downtown Bellevue. ST3 (2016) re-funded the two Downtown Redmond stations (including Marymoor Village), planned by 2024; actual opening May 10, 2025. Per methodology (use earliest projected date), we use the ST2-era projection (~2021, consistent with the broader East Link Overlake segment opening year), not the later ST3 projection of 2024. Source: Wikipedia (Downtown Redmond station article).
- Official project baseline was mid-2023; delayed further due to I-90 floating bridge plinth replacement issues discovered early 2022.
- initial_DEIS_date = 12/12/08 — PRIMARY SOURCE: East Link Light Rail Project DEIS published in the Federal Register on **December 12, 2008** (CEQ No. 20080502). Confirmed by EPA Region 10 comment letter dated February 24, 2009 (EPTA-088, Ref 06-052-FTA); file: 6_sources/fed_funding_records/SoundTransit/20080502.pdf. SECONDARY CONFIRMATION: EPA Region 10 SDEIS letter dated January 7, 2011 (CEQ No. 20100442) states "The East Link Draft EIS, which was issued in 2008, did not identify a preferred alternative." File: 20100442.pdf. FEIS reviewed August 10, 2011 (file: 20110219.pdf).
- Coordinates for Judkins Park (~-122.304, 47.595) and Mercer Island (~-122.237, 47.573) are approximate, estimated from I-90 median locations near 23rd Ave S/Rainier Ave S (Seattle) and 77th Ave SE (Mercer Island). Verify against King County GIS (rst_linkstationpoints) or GTFS feed.

### Crosslake Connection (Judkins Park + Mercer Island, opened March 28, 2026):
- Open date: March 28, 2026 — Source: Sound Transit press release (soundtransit.org/get-to-know-us/news-events/news-releases/crosslake-connection-opens-march-28), Fox 13 Seattle
- These two stations complete the 2 Line connection across Lake Washington (I-90 floating bridge). Completion was delayed from the broader East Link opening (April 2024) specifically due to the plinth replacement engineering challenge.
- The 2 Line now connects Redmond to Seattle's International District/Chinatown station (1 Line junction).
- This completes the Sound Transit 2 (2008 ballot measure) Link light rail buildout. ST2 system recap: see Seattle Transit Blog (Feb 2026).

### Federal Way Link Extension (3 stations, opened Dec 6, 2025):
- Open date: Dec 6, 2025 — Source: Sound Transit press release, The Urbanist
- Expected date by station (using earliest ST2 projections per methodology):
  - Kent Des Moines: 1/1/20 — ST2 plan (st2_plan_web.pdf): "vicinity of Highline Community College (scheduled to open by 2020)." Kent Des Moines station is the Highline CC-area station.
  - Star Lake: 1/1/23 — ST2 plan: "Redondo/Star Lake (scheduled to open by 2023)." Star Lake station (near S 272nd) corresponds to the ST2 Redondo/Star Lake station.
  - Federal Way Downtown: 1/1/23 — Federal Way Downtown appears to be beyond the committed ST2 Redondo/Star Lake terminus; included in the Federal Way Link DEIS (April 2015) scope. Using 1/1/23 as earliest reasonable projection (same ST2 corridor year). NEEDS VERIFICATION from Federal Way DEIS or FFGA for an earlier projected opening year if one was stated. Also delayed by concrete strike and construction issues (Sound Transit, The Urbanist).
- NOTE: Angle Lake (S 200th St) was the first of the originally planned "Federal Way extension" stations, built separately under TIGER grants and opened 2016; it is listed under its own entry above.
- initial_DEIS_date = 4/10/15 — PRIMARY SOURCE: Sound Transit news release "Draft Environmental Impact Statement released for extending light rail to Kent/Des Moines, Federal Way" dated April 10, 2015 (soundtransit.org). Public comment period ran April 10 – May 26, 2015. Final EIS published November 18, 2016. The Federal Way Link DEIS is a separate project-level document from the East Link DEIS (December 2008) and the Lynnwood DEIS (July 2013).
- Coordinates: estimated from known locations along I-5 corridor south of SeaTac

---

## WMATA Metrorail (WMATA_Metro_Stations.csv)
*Note: WMATA EIS records are available in 6_sources/EIS_records/WMATA_silver_line/, 6_sources/EIS_records/WMATA_potomac_yard/, and 6_sources/EIS_records/MD_purple_line/ and have been reviewed — dates to be updated in a future pass.*
