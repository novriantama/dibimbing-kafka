include .env

help:
	@echo "## docker-build		- Build Docker Images for Mac (arm64) including its inter-container network."

docker-build:
	@docker network inspect kafka-network >/dev/null 2>&1 || docker network create kafka-network
	@docker build -t dataeng-kafka/jupyter -f ./docker/Dockerfile.jupyter .

jupyter:
	@echo '__________________________________________________________'
	@echo 'Creating Jupyter Notebook Cluster at http://localhost:${JUPYTER_PORT} ...'
	@echo '__________________________________________________________'
	@docker compose -f ./docker/docker-compose-jupyter.yml --env-file .env up -d
	@echo 'Created...'
	@echo 'Processing token...'
	@sleep 20
	@docker logs ${JUPYTER_CONTAINER_NAME} 2>&1 | grep '\?token\=' -m 1 | cut -d '=' -f2
	@echo '==========================================================='

kafka: kafka-create kafka-create-topic

kafka-create:
	@echo '__________________________________________________________'
	@echo 'Creating Kafka Cluster ...'
	@echo '__________________________________________________________'
	@docker compose -f ./docker/docker-compose-kafka.yml --env-file .env up -d
	@echo 'Waiting for uptime on http://localhost:8083 ...'
	@sleep 20
	@echo '==========================================================='

kafka-create-topic:
	@docker exec ${KAFKA_CONTAINER_NAME} \
		kafka-topics.sh --create \
		--partitions ${KAFKA_PARTITION} \
		--replication-factor ${KAFKA_REPLICATION} \
		--bootstrap-server ${KAFKA_HOST}:9092 \
		--topic ${KAFKA_TOPIC_NAME}

proto: 
	@protoc --python_out=. ./protobuf/protobuf_schema.proto