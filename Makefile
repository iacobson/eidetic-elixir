init: clean hex deps

clean:
	@docker-compose down -v

hex:
	@docker-compose run --rm elixir do local.hex --force, local.rebar --force

deps:
	@docker-compose run --rm elixir deps.get

test:
	@docker-compose run --rm elixir test

.PHONY: test deps
