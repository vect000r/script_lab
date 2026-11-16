#!/bin/bash

# Skrypt automatycznego testowania dla proga i progb
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
ERRORS=0

echo -e "${BLUE}=== URUCHAMIANIE TESTÓW DLA proga I progb ===${NC}\n"

# Sprawdzenie, czy pliki wykonywalne istnieją
if [ ! -x "./proga" ]; then
	echo -e "${RED}[BŁĄD] ./proga nie istnieje lub nie ma praw wykonywalności!${NC}"
	exit 1
fi

if [ ! -x "./progb" ]; then
	echo -e "${RED}[BŁĄD] ./progb nie istnieje lub nie ma praw wykonywalności!${NC}"
	exit 1
fi

TEST_DIR="dane_test_env"
ROOT_DASH_DIR="./-root space"

# Czyszczenie katalogów testowych
rm -rf -- "$TEST_DIR" "$ROOT_DASH_DIR"

cleanup() {
	rm -rf -- "$TEST_DIR" "$ROOT_DASH_DIR"
}

trap cleanup EXIT

# Akceptuj zarówno format z jednym polem w wierszu, jak i format tabelaryczny
# (pola rozdzielone tabulatorami), który mogą wypisywać programy.
normalize_output() {
	sed -E 's/[[:blank:]]+/\n/g'
}

# 1. Tworzenie struktury katalogu z przykładu ex3.txt
mkdir -p -- "$TEST_DIR/pod"
printf 'hello' > "$TEST_DIR/a.txt"
printf 'ala ma kota!' > "$TEST_DIR/ala ma kota.txt"
printf '123' > "$TEST_DIR/pod/x.dat"

# 2. Tworzenie struktury z testu 13 (katalog zaczynający się od '-')
mkdir -p -- "$ROOT_DASH_DIR/sub"
printf '%s' $'\x61' > "$ROOT_DASH_DIR/a"
printf '%s' $'\x78' > "$ROOT_DASH_DIR/sub/x"

# -------------------------------------------------------------
# TEST 1: proga - przykładowy katalog z treści zadania (ex3.txt)
# -------------------------------------------------------------
echo -e "${BLUE}Test 1: proga na standardowym katalogu ('$TEST_DIR')${NC}"
OUT_A=$(./proga "$TEST_DIR" | normalize_output)
EXPECTED_A=$(cat << 'EOF'
612e747874
5
5d41402abc4b2a76b9719d911017c592
616c61206d61206b6f74612e747874
12
bd2008db0e7f23377f58de48c30cbf4a
706f642f782e646174
3
202cb962ac59075b964b07152d234b70
EOF
)

if [ "$OUT_A" = "$EXPECTED_A" ]; then
	echo -e "${GREEN}[PASS] Test 1 (proga przykład): Zgodny!${NC}"
else
	echo -e "${RED}[FAIL] Test 1 (proga przykład): Niepoprawny wynik:${NC}"
	echo "Otrzymano:"
	echo "$OUT_A"
	echo "Oczekiwano:"
	echo "$EXPECTED_A"
	ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------------
# TEST 2: proga - nazwa katalogu z myślnikiem i spacją (Test 13)
# -------------------------------------------------------------
echo -e "${BLUE}Test 2: proga na katalogu z myślnikiem ('-root space/')${NC}"
OUT_A_DASH=$(./proga "-root space/" | normalize_output)
EXPECTED_A_DASH=$(cat << 'EOF'
61
1
0cc175b9c0f1b6a831c399e269772661
7375622f78
1
9dd4e461268c8034f5c8564e155c67a6
EOF
)

if [ "$OUT_A_DASH" = "$EXPECTED_A_DASH" ]; then
	echo -e "${GREEN}[PASS] Test 2 (proga test 13): Zgodny!${NC}"
else
	echo -e "${RED}[FAIL] Test 2 (proga test 13): Niepoprawny wynik:${NC}"
	echo "Otrzymano:"
	echo "$OUT_A_DASH"
	echo "Oczekiwano:"
	echo "$EXPECTED_A_DASH"
	ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------------
# TEST 3: progb - strumień wejściowy z przykładu zadania
# -------------------------------------------------------------
echo -e "${BLUE}Test 3: progb ze strumieniem z find -print0${NC}"
OUT_B=$(find "$TEST_DIR" -type f -print0 | ./progb | normalize_output)
EXPECTED_B=$(cat << 'EOF'
64616e655f746573745f656e762f612e747874
5
5d41402abc4b2a76b9719d911017c592
64616e655f746573745f656e762f616c61206d61206b6f74612e747874
12
bd2008db0e7f23377f58de48c30cbf4a
64616e655f746573745f656e762f706f642f782e646174
3
202cb962ac59075b964b07152d234b70
EOF
)

if [ "$OUT_B" = "$EXPECTED_B" ]; then
	echo -e "${GREEN}[PASS] Test 3 (progb przykład): Zgodny!${NC}"
else
	echo -e "${RED}[FAIL] Test 3 (progb przykład): Niepoprawny wynik:${NC}"
	echo "Otrzymano:"
	echo "$OUT_B"
	echo "Oczekiwano:"
	echo "$EXPECTED_B"
	ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------------
# TEST 4: progb - nazwy plików będące opcjami flag
# -------------------------------------------------------------
echo -e "${BLUE}Test 4: progb dla plików z myślnikami ('-', '-n', 'plain')${NC}"
printf '%s' $'\x64\x61\x73\x68' > '-'
printf '%s' $'\x6f\x70\x74\x69\x6f\x6e' > '-n'
printf '%s' $'\x70' > 'plain'

OUT_B_DASH=$(printf '%s\0' '-' '-n' 'plain' | ./progb | normalize_output)
rm -f -- '-' '-n' 'plain'

EXPECTED_B_DASH=$(cat << 'EOF'
2d
4
b999a7c3bcc5535b4c8e277e18b7b6e1
2d6e
6
ef3e30e070f70244fd6578d88a6b77ac
706c61696e
1
83878c91171338902e0fe0fb97a8c47a
EOF
)

if [ "$OUT_B_DASH" = "$EXPECTED_B_DASH" ]; then
	echo -e "${GREEN}[PASS] Test 4 (progb test 10): Zgodny!${NC}"
else
	echo -e "${RED}[FAIL] Test 4 (progb test 10): Niepoprawny wynik:${NC}"
	echo "Otrzymano:"
	echo "$OUT_B_DASH"
	echo "Oczekiwano:"
	echo "$EXPECTED_B_DASH"
	ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------------
# TEST 5: progb - puste wejście
# -------------------------------------------------------------
echo -e "${BLUE}Test 5: progb na pustym wejściu${NC}"
OUT_EMPTY=$(printf '' | ./progb)

if [ -z "$OUT_EMPTY" ]; then
	echo -e "${GREEN}[PASS] Test 5 (puste wejście): Zwrócono 0 bajtów!${NC}"
else
	echo -e "${RED}[FAIL] Test 5 (puste wejście): Zwrócono niepotrzebne dane!${NC}"
	ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------------
# PODSUMOWANIE
# -------------------------------------------------------------
if [ $ERRORS -eq 0 ]; then
	echo -e "${GREEN}=========================================${NC}"
	echo -e "${GREEN} WSZYSTKIE TESTY ZALICZONE! (5/5) ${NC}"
	echo -e "${GREEN}=========================================${NC}"
	exit 0
else
	echo -e "${RED}=========================================${NC}"
	echo -e "${RED} LICZBA BŁĘDÓW: $ERRORS ${NC}"
	echo -e "${RED}=========================================${NC}"
	exit 1
fi
