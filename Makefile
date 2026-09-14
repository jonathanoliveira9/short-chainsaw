up:
	RAILS_MASTER_KEY=$$(cat config/master.key) docker compose up

down:
	RAILS_MASTER_KEY=$$(cat config/master.key) docker compose down

bash:
	docker exec -it short-chainsaw bash