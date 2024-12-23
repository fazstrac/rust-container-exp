# Rust in Container experiment

A little pass-time experiment to learn Rust and howto deploy in container using multi-stage building. Far from optimal :-)

Stages:
1. Stage0 creates a Debian minimal environment and fetches the [WHO Air Quality dataset V6.0](https://www.who.int/publications/m/item/who-ambient-air-quality-database-%28update-2023%29) and saves it in an DuckDB database.
2. Stage1 compiles a minimal Rust program to access the database from stage0, using the Rust official Docker image
3. Stage2 creates another Debian minimal environment to run the compiled Rust program
