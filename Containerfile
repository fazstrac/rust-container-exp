# *** STAGE 0 ***
# Get example database
FROM debian:12-slim as stage0 

WORKDIR /app
RUN apt-get update && \
apt-get install -y wget unzip && \
wget https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip && unzip duckdb_cli-linux-amd64.zip && \
rm *.zip

WORKDIR /app/duckdb_poc/db
COPY <<9e580b ./duckdb_script
install spatial;
load spatial;
create table who_air_quality as select * from st_read("who_ambient_air_quality_database_version_2023_v6.0.xlsx", layer = "Update 2023 (V6.0)");
9e580b

RUN wget -O who_ambient_air_quality_database_version_2023_v6.0.xlsx "https://cdn.who.int/media/docs/default-source/air-pollution-documents/ambient-air-pollution/who_ambient_air_quality_database_version_2023_(v6.0).xlsx?sfvrsn=1d71f50c_5&download=true" && \
(cat duckdb_script | /app/duckdb testdatabase.db) && \
rm who_ambient_air_quality_database_version_2023_v6.0.xlsx duckdb_script

# *** STAGE 1 ***
# Compile a rust test file
FROM rust:1.83-slim-bookworm as stage1

WORKDIR /app/
COPY --from=stage0 /app/ ./

WORKDIR /app/libduckdb
RUN apt-get update && apt-get install -y wget unzip && \
wget https://github.com/duckdb/duckdb/releases/download/v1.1.3/libduckdb-linux-amd64.zip && \
unzip libduckdb-linux-amd64.zip && \
rm libduckdb-linux-amd64.zip

WORKDIR /app/duckdb_poc
COPY <<d74f65 ./Cargo.toml
[package]
name = "duckdb_poc"
version = "0.1.0"
edition = "2021"

[profile.dev]
opt-level = 0

[profile.release]
opt-level = 3
d74f65

COPY . .

ENV DUCKDB_LIB_DIR=/app/libduckdb
ENV DUCKDB_INCLUDE_DIR=/app/libduckdb
RUN cargo add duckdb && \
cargo add polars && \
cargo build --release

# *** STAGE 2 ***
# Run a rust test file
FROM debian:12-slim as stage2

WORKDIR /app
COPY --from=stage1 /app/libduckdb ./libduckdb/
COPY --from=stage1 /app/duckdb_poc/target/release/duckdb_poc ./
COPY --from=stage1 /app/duckdb_poc/db ./
COPY --from=stage0 /app/duckdb ./

COPY <<d8cecf /etc/ld.so.conf.d/duckdb.conf
/app/libduckdb
d8cecf

RUN ldconfig

CMD ["/app/duckdb_poc"]
