# ************************************************************************** #
#   Makefile for Inception                                                   #
# ************************************************************************** #

DC        := docker compose
DC_FILE   := ./srcs/docker-compose.yml

DATA_DIR_MARIADB  := /home/athonda/data/mariadb
DATA_DIR_WORDPRESS:= /home/athonda/data/wordpress

.PHONY: all up down build logs clean fclean re

all: dir up

dir:
	mkdir -p $(DATA_DIR_MARIADB)
	mkdir -p $(DATA_DIR_WORDPRESS)
#	sudo chown -R 65534:65534 $(DATA_DIR_WORDPRESS)
#	sudo chmod -R 755 $(DATA_DIR_WORDPRESS)

up:
	$(DC) -f $(DC_FILE) up -d --build

down:
	$(DC) -f $(DC_FILE) down

end:
	$(DC) -f $(DC_FILE) down

build:
	$(DC) -f $(DC_FILE) build

logs:
	$(DC) -f $(DC_FILE) logs -f

clean: down
	$(DC) -f $(DC_FILE) down -v
	docker stop $$(docker ps -a -q) || true
	docker rm $$(docker ps -a -q) || true
	docker rmi $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true
	docker network rm $$(docker network ls -q) || true

fclean: clean
	if [ -d "$(DATA_DIR_MARIADB)" ]; then sudo rm -rf "$(DATA_DIR_MARIADB)"; fi
	if [ -d "$(DATA_DIR_WORDPRESS)" ]; then sudo rm -rf "$(DATA_DIR_WORDPRESS)"; fi

re: fclean
	$(DC) -f $(DC_FILE) up -d --build


# **************************************************************************** #
# make          # = make up
# make up       # コンテナをバックグラウンド起動
# make down     # 停止
# make clean    # 停止＋ボリューム削除
# make fclean   # さらに /home/$USER/data/* を削除
# make re       # クリーン＋再ビルド起動
