#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Poprawne użycie: test.sh <ścieżka do pliku binarnego testowanego programu>"
    exit 1
fi

BASEDIR="$(dirname "$0")"

ulimit -v $(( 128 * 1024 )) # 128 MB

BRED='\033[1;31m'
BWHITE='\033[1;37m'
NC='\033[0m' # No Color

describe() {
    echo -e "${BWHITE}$1${NC}"
}

check() {
    exit_code=$?
    
    if [ $exit_code -ne $1 ]
    then
        if [ $# -eq 2 ]
        then
            printf "${BRED}$2\n${NC}"
        fi

        printf "${BRED}Program powinien zwrócić $1, a zwrócił $exit_code.\n${NC}"
    fi
}

check_output() {
    printf "${BRED}"
    cmp $1 $2 > /dev/null
    exit_code=$?
    printf "${NC}"

    if [ $exit_code -ne 0 ]
    then
        printf "${BRED}$3\n${NC}"
        
        printf "${BRED}"
        cmp $1 $2
        printf "${NC}"
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


testdir=testy_poprawnosci_male
describe "Testowanie na małych losowych testach poprawności"

for infile in "$BASEDIR"/$testdir/*.in
do
    no_dir="${infile##*/}"
    base="${no_dir%.in}"

    n="${base##*_}"
    without_id_text="${base#id_}"
    id="${without_id_text%%_*}"

    outfile="$BASEDIR"/$testdir/id_$id.out

    "$1" "$n" < $infile > $tmpfile
    check 0 "$testdir/$no_dir id=$id n=$n"
    check_output $tmpfile $outfile "$testdir/$no_dir id=$id n=$n"
done