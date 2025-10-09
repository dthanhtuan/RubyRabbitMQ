#!/usr/bin/env bash

exec docker compose exec -it web bash -lc "bundle exec rails console"