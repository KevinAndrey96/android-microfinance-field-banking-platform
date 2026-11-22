.PHONY: setup test seed server docker-up docker-down lint

setup:
	cd backend/rails-api && bundle install && bundle exec rails db:prepare

test:
	cd backend/rails-api && bundle exec rails test

seed:
	cd backend/rails-api && bundle exec rails db:seed

server:
	cd backend/rails-api && bundle exec rails server -p 3000

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

lint:
	cd backend/rails-api && bundle exec rubocop
