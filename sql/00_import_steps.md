# Step 0: Download the BTS data and build the database

## 1. Download one month of flights
1. Go to the US Bureau of Transportation Statistics (BTS) airline on-time database: <https://www.transtats.bts.gov/Tables.asp?QO_VQ=EFD>
2. Next to **Reporting Carrier On-Time Performance (1987-present)**, click **Download**.
3. Pick a **year and month** (for example, the most recent month).
4. To keep the file small, tick only these fields (the queries use exactly these names):
   `FlightDate`, `DayOfWeek`, `Reporting_Airline`, `Origin`, `Dest`, `CRSDepTime`, `DepDelay`, `ArrDelay`, `ArrDel15`, `Cancelled`, `CancellationCode`, `Diverted`, `CarrierDelay`, `WeatherDelay`, `NASDelay`, `SecurityDelay`, `LateAircraftDelay`
5. Click **Download** and unzip the CSV. One month is about 500,000–600,000 flights.

> The data covers **domestic US flights by US reporting carriers**. Canadian airlines and cross-border flights aren't included.

## 2. Import into SQLite
1. **DB Browser for SQLite** → **New Database** → save as `flights.db`.
2. **File → Import → Table from CSV file…** → select the CSV.
   - **Table name: `flights`**
   - Tick **Column names in first line**, with the separator set to **comma** and the quote character set to `"`.
3. **Write Changes** (Ctrl+S). The import may take a minute.

The queries create a view (`f`) that converts the text columns to numbers, so nothing else is needed.

## 3. Run
Open `01_delay_analysis.sql` and run one query at a time. To study a different airport in queries 4.2 and 4.3, change `'EWR'`.
