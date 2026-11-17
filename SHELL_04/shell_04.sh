#!/usr/bin/env bash
set -euo pipefail

# Kolory do czytelnego wypisywania wyników
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

WORKDIR="test_env"

echo -e "${BLUE}=== Przygotowywanie środowiska testowego w katalogu: ${WORKDIR} ===${NC}"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/src/pod" "$WORKDIR/src/pusty_katalog" "$WORKDIR/src/sciezka ze spacja"
mkdir -p "$WORKDIR/prev/pod"

# 1. Tworzenie plików w SRC
printf 'aaaaa' > "$WORKDIR/src/a.txt"                       # Nowy plik (5 B)
printf '12345678' > "$WORKDIR/src/b.txt"                    # Bez zmian względem PREV (8 B)
printf 'nowy_c_1234' > "$WORKDIR/src/pod/c.txt"              # Zmieniony plik (12 B)
printf 'zawartosc ze spacja' > "$WORKDIR/src/sciezka ze spacja/plik ze spacja.txt"

# 2. Tworzenie plików w PREV
printf '12345678' > "$WORKDIR/prev/b.txt"                    # Identyczna zawartość z src/b.txt
printf 'stary_c_val' > "$WORKDIR/prev/pod/c.txt"             # Inna zawartość niż w src/pod/c.txt
printf 'ten plik powinen zostac zignorowany' > "$WORKDIR/prev/stary.txt" # Usunięty w SRC

echo -e "${GREEN}Struktura katalogów testowych została utworzona:${NC}"
echo "  $WORKDIR/src/"
echo "    ├── a.txt (nowy plik)"
echo "    ├── b.txt (niezmieniony)"
echo "    ├── pod/c.txt (zmieniony)"
echo "    ├── pusty_katalog/"
echo "    └── sciezka ze spacja/plik ze spacja.txt"
echo "  $WORKDIR/prev/"
echo "    ├── b.txt"
echo "    ├── pod/c.txt"
echo "    └── stary.txt (nie ma w src)"
echo ""

# Sprawdzenie czy skrypt snapshot istnieje
SNAPSHOT_BIN="./snapshot"

if [[ ! -x "$SNAPSHOT_BIN" ]]; then
    echo -e "${YELLOW}Uwaga: Plik wywoływalny '$SNAPSHOT_BIN' nie istnieje w bieżącym katalogu.${NC}"
    echo "Stworzono środowisko testowe. Gdy napiszesz program 'snapshot', uruchom ten skrypt ponownie,"
    echo "aby przeprowadzić automatyczne testy."
    echo ""
    echo "Możesz też przetestować wywołanie ręcznie:"
    echo "  ./snapshot $WORKDIR/src $WORKDIR/prev $WORKDIR/dest"
    exit 0
fi

echo -e "${BLUE}=== Uruchamianie testów dla $SNAPSHOT_BIN ===${NC}"

# Test 1: Pierwszy snapshot (PREV = -)
echo -e "\n${YELLOW}[TEST 1] Snapshot bez poprzedniego katalogu (PREV = -)${NC}"
DEST1="$WORKDIR/dest_first"
rm -rf "$DEST1"

RAPORT1=$("$SNAPSHOT_BIN" "$WORKDIR/src" - "$DEST1")
echo "Raport z pierwszego wykonania:"
echo "$RAPORT1"

# Sprawdzenie czy dest1 został utworzony
if [[ -d "$DEST1" ]]; then
    echo -e "${GREEN}✓ Katalog $DEST1 został poprawnie utworzony.${NC}"
else
    echo -e "${RED}✗ BŁĄD: Katalog $DEST1 nie istnieje!${NC}"
fi

# Test 2: Drugi snapshot z użyciem PREV
echo -e "\n${YELLOW}[TEST 2] Snapshot z poprzednim katalogiem PREV${NC}"
DEST2="$WORKDIR/dest_prev"
rm -rf "$DEST2"

RAPORT2=$("$SNAPSHOT_BIN" "$WORKDIR/src" "$WORKDIR/prev" "$DEST2")
echo "Raport z wykonania z PREV:"
echo "$RAPORT2"

# Weryfikacja twardych dowiązań (hardlinków)
echo -e "\n${BLUE}=== Weryfikacja wyników TESTU 2 ===${NC}"

ERRORS=0

# Check 1: b.txt powien być LINK (ten sam inode co prev/b.txt)
INODE_PREV_B=$(stat -c "%d %i" "$WORKDIR/prev/b.txt")
INODE_DEST_B=$(stat -c "%d %i" "$DEST2/b.txt" 2>/dev/null || echo "brak")

if [[ "$INODE_PREV_B" == "$INODE_DEST_B" ]]; then
    echo -e "${GREEN}✓ b.txt jest twardym dowiązaniem do prev/b.txt (inode: $INODE_DEST_B)${NC}"
else
    echo -e "${RED}✗ BŁĄD: b.txt powinien być hardlinkiem do prev/b.txt! (PREV: $INODE_PREV_B vs DEST: $INODE_DEST_B)${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: a.txt powinien być COPY (inny inode niż prev - bo go tam nie ma)
INODE_SRC_A=$(stat -c "%d %i" "$WORKDIR/src/a.txt")
INODE_DEST_A=$(stat -c "%d %i" "$DEST2/a.txt" 2>/dev/null || echo "brak")

if [[ -f "$DEST2/a.txt" && "$INODE_SRC_A" != "$INODE_DEST_A" ]]; then
    echo -e "${GREEN}✓ a.txt został skopiowany jako osobny plik.${NC}"
else
    echo -e "${RED}✗ BŁĄD: a.txt nie został poprawnie skopiowany.${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: pod/c.txt powinien być COPY (inna zawartość)
INODE_PREV_C=$(stat -c "%d %i" "$WORKDIR/prev/pod/c.txt")
INODE_DEST_C=$(stat -c "%d %i" "$DEST2/pod/c.txt" 2>/dev/null || echo "brak")

if [[ -f "$DEST2/pod/c.txt" && "$INODE_PREV_C" != "$INODE_DEST_C" ]]; then
    echo -e "${GREEN}✓ pod/c.txt został skopiowany (zawartość uległa zmianie).${NC}"
else
    echo -e "${RED}✗ BŁĄD: pod/c.txt powinien być nową kopią, a nie hardlinkiem!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: stary.txt nie powinien istnieć w DEST
if [[ ! -e "$DEST2/stary.txt" ]]; then
    echo -e "${GREEN}✓ prev/stary.txt nie został przeniesiony do DEST (poprawnie zignorowany).${NC}"
else
    echo -e "${RED}✗ BŁĄD: stary.txt pojawił się w DEST!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: pliki ze spacjami
if [[ -f "$DEST2/sciezka ze spacja/plik ze spacja.txt" ]]; then
    echo -e "${GREEN}✓ Obsługa ścieżek ze spacjami działa poprawnie.${NC}"
else
    echo -e "${RED}✗ BŁĄD: Nie znaleziono pliku ze spacjami w DEST.${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 6: puste katalogi
if [[ -d "$DEST2/pusty_katalog" ]]; then
    echo -e "${GREEN}✓ Pusty podkatalog został odtworzony.${NC}"
else
    echo -e "${RED}✗ BŁĄD: Pusty podkatalog nie został odtworzony.${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
    echo -e "${GREEN}=== WSZYSTKIE TESTY ZAKOŃCZONE SUKCESEM! ===${NC}"
else
    echo -e "${RED}=== WYKRYTO $ERRORS BŁĘDÓW W TESTACH. ===${NC}"
fi
