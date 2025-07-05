# Transit Effects

Welcome to my project measuring the effects of increased public transit access. My initial interest in this topic was spurred by my experiences living in different American cities, seeing different levels of engagment with public transit. But it has since been augmented by my interest in the effects of social and physical networks on tangible financial indicators like income, credit access, and financial literacy/health. The reason this repo was originally named "Transit Credit Access" is because that metric was what most interested me in this topic; however, I've decided to focus on labor-market indicators like worker flows and income levels for now due to data constraints and the way I've designed my identification strategy. 

I have a few goals for this project: 

- [ ] Construct a comprehensive database of construction delays for public transit projects in the US begun since 2000. 
- [ ] Measure the effects of new transit stations on surrounding labor markets, focusing on workers' residential locations. 

## How To Use This Repo:
The workflow I've set up here is like so: 

### Data
This folder is where I store all of the raw data I'm using. These are divided into categories: 

  - **Transit Cost Project Data:** This is data collected by the [Transit Costs Project](https://transitcosts.com/), run out of NYU. While I certainly rely on their data as a baseline for all of the stations built in the US since 2000, I supplement this as needed with stations I notice aren't included (I'm sure to email the TCP staff with any discrepancies I find). 
  - **LODES:** The U.S. Census Bureau makes multiple measures of labor market dynamics available via the [Longitudinal Employer-Household Dynamics](https://lehd.ces.census.gov/data/) data. I use public-access LEHD Origin-Destination Employment Statistics (LODES) data for information on job flows tied to residential location. These data files are far to big to include in this repo, but you can download the data [here](https://lehd.ces.census.gov/data/lodes/). As I work I will try to make this entire project as replicable as possible and will include further instructions for how to download the data in a way that behaves well with my files. 
  - **Station Geographies:** These are .csv and Excel files I am creating manually. I am collecting all of the stations denoted by the Transit Costs Project and finding their exact longitude and latitude for mapping later. Importantly, this is also where I'm documenting these stations' opening dates, initial expected opening date, and initial opening date as denoted in the draft environmental impact statement for each project. I'll talk more about these EIS drafts in the [Sources](### Sources) section. 

### Code

### Output

### Data Dictionaries, Literature

### Sources