#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Poprawne użycie: testy_blednego_wejscia.sh <ścieżka do pliku binarnego testowanego programu>"
    exit 1
fi

BASEDIR="$(dirname "$0")"

ulimit -v $((1<<17)) # 128 MB

BRED='\033[1;31m'
BWHITE='\033[1;37m'
NC='\033[0m' # No Color

describe() {
    echo -e "${BWHITE}$1${NC}"
}

check() {
    if [ $? -ne $1 ]
    then
        printf "${BRED}Program powinien zwrócić $1, a zwrócił $?.\n${NC}"
    fi
}

for filename in "$BASEDIR"/testy_blednego_wejscia/*
do
    describe "${filename##*/}"
    "$1" 0 < $filename > /dev/null
    check 1
done

for n in '' ' ' 'a' 'A' '-1' '4294967296' '10000000000000000000' '18446744073709553753' ':3' '3/4'
do
    describe "Testowanie błędnego n = '$n'."
    echo "" | "$1" "$n" > /dev/null
    check 1
done

describe "Testowanie braku parametru n"
echo "" | "$1" > /dev/null
check 1

describe "Testowanie nadmiarowych parametrów"
echo "" | "$1" 69 420 > /dev/null
check 1

describe "Testowanie błędu I/O na wejściu (EBADF)"
"$1" 123 0>/dev/null
check 1

describe "Testowanie błędu I/O na wejściu (EISDIR)"
"$1" 123 <.
check 1

describe "Testowanie błędu I/O na wyjściu (ENOSPC)"
"$1" 3 < "$BASEDIR"/baseline/algae.in > /dev/full
check 1

describe "Testowanie wejścia większego niż dostępny RAM"
yes 'meowmeowmeowmeow' | tr -d '\n' | "$1" 123 >/dev/null
check 1

tmpfile="$(mktemp)"
trap "rm $tmpfile" EXIT

testdir=baseline
for infile in "$BASEDIR"/$testdir/*.in; do
    filename="${infile##*/}"
    testname="${filename%.in}"
    for outfile in "$BASEDIR"/$testdir/$testname.out.*; do
        n="${outfile##*.}"
        describe "$testdir/$filename n=$n"
        "$1" "$n" < $infile > $tmpfile
        check 0
        printf "${BRED}"
        cmp $tmpfile $outfile
        printf "${NC}"
    done
done
