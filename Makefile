# ************************************************************************** #
#   Makefile for Inception                                                   #
# ************************************************************************** #

DC        := docker compose
DC_FILE   := ./srcs/docker-compose.yml

DATA_DIR_MARIADB  := /home/athonda/data/mariadb
DATA_DIR_WORDPRESS:= /home/athonda/data/wordpress

.PHONY: all up down build logs clean fclean re

all: up

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

fclean: clean
	if [ -d "$(DATA_DIR_MARIADB)" ]; then rm -rf "$(DATA_DIR_MARIADB)"; fi
	if [ -d "$(DATA_DIR_WORDPRESS)" ]; then rm -rf "$(DATA_DIR_WORDPRESS)"; fi

re: fclean
	$(DC) -f $(DC_FILE) up -d --build


# **************************************************************************** #
# make          # = make up
# make up       # コンテナをバックグラウンド起動
# make down     # 停止
# make clean    # 停止＋ボリューム削除
# make fclean   # さらに /home/$USER/data/* を削除
# make re       # クリーン＋再ビルド起動
