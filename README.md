# Publish Shibboleth SP Image

This repository is for the Publish Shibboleth SP Docker image. It provides
a preconigured Shibboleth SP and allows changing some settings via
environment variables.

Instead of having a normal branch structure with `main` and `develop`, this
repository is organized with branches for the base Docker image. Current
branches used for building:

- `main/ubuntu22.04`: production as of June 2022.
- `main/ubuntu20.04`
- `main/ubuntu18.04`: production before June 2022.