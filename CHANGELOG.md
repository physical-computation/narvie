# Changelog

## [0.3.0] - 2019-03-29

- `narvie` cli is a single binary with `--simulate` option that requires no external set up.
- `narvie` processor contains a binary that writes to tcp port 8001 in the same way that the hardware version of `narvie` writes to a serialport.
- `narvie` processor can also be included as a library, exposing the `run_narvie()` function.
