# Flight Delay Analysis: What Really Makes Flights Late?

**Using the US government's public flight-by-flight on-time data to measure delays by airline, airport, time of day and cause, and to show how one late aircraft can cascade into a day of delays.**

Uses **real, public data** from the US Bureau of Transportation Statistics (BTS). As a flight attendant, I work on the operational side of on-time performance: turnarounds, crew connections and the knock-on effect of a late inbound aircraft. This project quantifies those patterns.

**Tools:** SQL (SQLite: views, CTEs, aggregation) · Python (tests) · Excel / Power BI for charts

---

## Questions

1. What share of flights arrive on time (less than 15 minutes late), and how does that vary by airline?
2. Do delays build up through the day?
3. What causes delays: the airline, weather, air traffic control, or a late-arriving aircraft?
4. Why are flights cancelled?
5. Which airports have the worst on-time performance? *(Example: Newark, EWR)*

## What's in the repo

| Path | What it does |
|---|---|
| `sql/00_import_steps.md` | Which BTS fields to download, and how to load them into SQLite |
| `sql/01_delay_analysis.sql` | All queries: overview, airlines, hour of day, day of week, delay causes, cancellation reasons, airports, single-airport detail |
| `tests/test_queries.py` | Builds a small flights table with known answers and checks every query (`python tests/test_queries.py`) |

### Definitions (from BTS)
- **On time** means arriving less than 15 minutes after the scheduled time (`ArrDel15 = 0`).
- **Delay causes** are reported in minutes for flights 15+ minutes late:
  - **Carrier:** crew, maintenance, fuelling, baggage
  - **National Aviation System:** air traffic control, airport operations, heavy traffic
  - **Weather:** extreme weather only
  - **Security**
  - **Late-arriving aircraft:** the previous flight with the same plane was late
- **Cancellation codes:** A = carrier, B = weather, C = National Aviation System, D = security.

## How to run it

1. Follow `sql/00_import_steps.md` to download one month of data and build `flights.db`.
2. Run each query in `sql/01_delay_analysis.sql` in DB Browser for SQLite.
3. Copy the results into the tables below.

---

## Results

*To be completed after running on the downloaded month. Month analyzed: `____`.*

| Metric | Value |
|---|---|
| Scheduled flights | |
| On-time arrival % | |
| Cancelled % | |
| Avg arrival delay (min) | |
| Biggest delay cause (% of delay minutes) | |
| Worst hour of day (on-time %) | |

### Delay minutes by cause

| Cause | % of delay minutes |
|---|---|
| Late-arriving aircraft | |
| Carrier | |
| National Aviation System | |
| Weather | |
| Security | |

### Findings
1. 
2. 
3. 

---

*Data: U.S. Department of Transportation, Bureau of Transportation Statistics, Reporting Carrier On-Time Performance. The raw data isn't included in this repo; download it from BTS.*
