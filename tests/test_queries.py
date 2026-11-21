"""Test for sql/01_delay_analysis.sql.

Builds a small BTS-style flights table in memory (all columns stored as text,
like a DB Browser CSV import, with blanks for missing values), runs every
query, and checks answers we can work out by hand.
Usage:  python tests/test_queries.py
"""
import os, re, sqlite3, sys

COLS = ["FlightDate", "DayOfWeek", "Reporting_Airline", "Origin", "Dest", "CRSDepTime", "DepDelay", "ArrDelay",
        "ArrDel15", "Cancelled", "CancellationCode", "Diverted", "CarrierDelay", "WeatherDelay", "NASDelay",
        "SecurityDelay", "LateAircraftDelay"]
db = sqlite3.connect(":memory:")
db.execute(f"CREATE TABLE flights ({', '.join(COLS)})")
rows = []
# Airline AA: 2,000 flights, all from EWR, 1,500 on time (delay 0), 500 late by 30 min (cause: 30 min late aircraft)
for i in range(2000):
    late = i < 500
    hour = "0700" if i % 2 == 0 else "1800"
    rows.append(["2025-07-01", "2", "AA", "EWR", "BOS", hour, "30.00" if late else "0.00", "30.00" if late else "0.00",
                 "1.00" if late else "0.00", "0.00", "", "0.00",
                 "0.00" if late else "", "0.00" if late else "", "0.00" if late else "", "0.00" if late else "", "30.00" if late else ""])
# Airline BB: 1,000 flights from ORD, 900 on time, 50 late by 60 min (carrier), 50 cancelled (weather, code B)
for i in range(1000):
    if i < 50:
        rows.append(["2025-07-05", "6", "BB", "ORD", "LGA", "1200", "60.00", "60.00", "1.00", "0.00", "", "0.00",
                     "60.00", "0.00", "0.00", "0.00", "0.00"])
    elif i < 100:
        rows.append(["2025-07-05", "6", "BB", "ORD", "LGA", "1200", "", "", "", "1.00", "B", "0.00", "", "", "", "", ""])
    else:
        rows.append(["2025-07-05", "6", "BB", "ORD", "LGA", "1200", "-5.00", "-5.00", "0.00", "0.00", "", "0.00",
                     "", "", "", "", ""])
db.executemany(f"INSERT INTO flights VALUES ({','.join('?' * len(COLS))})", rows)

SQL_FILE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "sql", "01_delay_analysis.sql")
res = {}
for block in re.split(r";\s*\n", open(SQL_FILE).read()):
    st = "\n".join(l for l in block.splitlines() if not l.strip().startswith("--")).strip()
    if not st:
        continue
    cur = db.execute(st)
    if cur.description:
        title = next((l.strip("- ").strip() for l in block.splitlines() if re.match(r"--\s*\d+\.\d+", l.strip())), "")
        res[title.split()[0]] = cur.fetchall()
        print("\n##", title, [d[0] for d in cur.description])
        for r in res[title.split()[0]][:6]:
            print(r)

ov = res["1.1"][0]
assert ov[0] == 3000 and ov[1] == 50 and ov[2] == 1.67, ov          # 50 / 3000 cancelled
assert ov[4] == round(100 * 2400 / 2950, 1), ov                       # 1500 + 900 on time of 2950 operated
air = {r[0]: r for r in res["1.2"]}
assert air["AA"][2] == 75.0 and air["BB"][2] == round(100 * 900 / 950, 1), res["1.2"]
assert air["AA"][4] == 30 and air["BB"][4] == 60
causes = {r[0]: r for r in res["3.1"]}
assert causes["Late-arriving aircraft"][1] == 15000 and causes["Late-arriving aircraft"][2] == round(100 * 15000 / 18000, 1)
assert causes["Carrier (crew, maintenance, fuelling, baggage)"][1] == 3000
assert res["3.2"][0][:2] == ("B Weather", 50) and res["3.2"][0][2] == 100.0
assert [r[0] for r in res["4.1"]] == ["EWR"], res["4.1"]            # ORD has only 1,000 departures (< 2,000)
assert res["4.2"][0][:3] == ("AA", 2000, 75.0)
hours = {r[0]: r for r in res["4.3"]}
assert hours[7][2] == 25.0 and hours[18][2] == 25.0 and hours[7][3] == 100.0
print("\nALL ASSERTIONS PASSED")
