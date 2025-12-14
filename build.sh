#!/bin/sh
export MIX_ENV=prod
mix deps.get --only prod
mix deps.compile
mix compile
mix assets.deploy
mix release