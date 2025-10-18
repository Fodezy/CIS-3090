CC := gcc
CFLAGS := -O2 -Wall -Wextra -Werror -pedantic -std=c11
LDFLAGS := -pthread

SRC_DIR := src
BIN := A1
SRC := $(SRC_DIR)/A1.c

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	del /Q $(BIN).exe 

