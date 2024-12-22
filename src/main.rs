use duckdb::{Connection, Result};

fn main() -> Result<()> {
    // Path to your database file
    let db_path = "./testdatabase.db";

    // Connect to the DuckDB database
    let conn = Connection::open(db_path)?;

    // Execute a query
    let mut stmt = conn.prepare("SELECT * FROM who_air_quality LIMIT 10")?;
    let mut rows = stmt.query([])?;

    // Print the results
    while let Some(row) = rows.next()? {
        let country: String = row.get("country_name")?;
        let year: i32 = row.get("year")?;
        let pm25: f64 = row.get("pm25_concentration")?;

        println!("Country: {}, Year: {}, PM2.5: {}", country, year, pm25);
    }

    Ok(())
}
