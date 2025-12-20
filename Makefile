# ************************************************************************** #
#   Makefile for Inception                                                   #
# ************************************************************************** #

DC			:= docker compose
DC_FILE		:= ./srcs/docker-compose.yml

# Keep host bind-mount paths consistent with docker-compose volumes.
# Source of truth: srcs/.env (LOGIN=<42login>)
LOGIN		:= $(strip $(shell sed -n 's/^LOGIN=//p' ./srcs/.env | head -n 1))
ifeq ($(LOGIN),)
$(error LOGIN is not set. Please set LOGIN in ./srcs/.env (e.g., LOGIN=athonda))
endif

DATA_DIR	:= /home/$(LOGIN)/data
DATA_DIR_MARIADB	:= $(DATA_DIR)/mariadb
DATA_DIR_WORDPRESS	:= $(DATA_DIR)/wordpress


.PHONY: all dir up down build logs clean fclean re

all: dir up

dir:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

up:
	$(DC) -f $(DC_FILE) up -d --build

down:
	$(DC) -f $(DC_FILE) down

build:
	$(DC) -f $(DC_FILE) build

start:
	$(DC) -f $(DC_FILE) start

stop:
	$(DC) -f $(DC_FILE) stop

logs:
	$(DC) -f $(DC_FILE) logs -f

clean: down

fclean: clean
	$(DC) -f $(DC_FILE) down --rmi all

deleteforeval: down
	$(DC) -f $(DC_FILE) down -v
	docker stop $$(docker ps -a -q) || true
	docker rm $$(docker ps -a -q) || true
	docker rmi $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true
	docker network rm $$(docker network ls -q) || true

deleteforevalpreparation: deleteforeval
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
