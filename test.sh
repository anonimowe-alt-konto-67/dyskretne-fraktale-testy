#!/bin/bash
if [ $# -ne 1 ]
then
    echo "Poprawne użycie: test.sh <ścieżka do pliku binarnego testowanego programu>"
    exit 1
fi

SOLUTION="$1"
BASEDIR="$(dirname "$0")"
num_failed=0

ulimit -v $(( 128 * 1024 )) # 128 MB

BRED='\033[1;31m'
BWHITE='\033[1;37m'
NC='\033[0m' # No Color

describe() {
    echo -e "${BWHITE}$1${NC}"
}

show_status() {
    echo -ne "${BWHITE}$1${NC}\r"
}

clear_status() {
    echo -ne "\033[2K"
}

# check $expected_return_code $description
check() {
    exit_code=$?
    
    if [ $exit_code -ne $1 ]
    then
        if [ $# -eq 2 ]
        then
            printf "${BRED}$2\n${NC}"
        fi

        printf "${BRED}Program powinien zwrócić $1, a zwrócił $exit_code.\n${NC}"
        (( num_failed++ ))
    fi
}

# check $file1 $file2 $description
check_output() {
    cmp $1 $2 > /dev/null
    exit_code=$?

    if [ $exit_code -ne 0 ]
    then
        printf "${BRED}$3\n${NC}"
        
        printf "${BRED}"
        cmp $1 $2
        printf "${NC}"
        (( num_failed++ ))
    fi
}

for filename in "$BASEDIR"/testy_blednego_wejscia/*
do
    describe "${filename##*/}"
    "$SOLUTION" 0 < $filename > /dev/null
    check 1
done

for n in '' ' ' 'a' 'A' '-1' '4294967296' '10000000000000000000' '18446744073709553753' ':3' '3/4'
do
    describe "Testowanie błędnego n = '$n'."
    echo "" | "$SOLUTION" "$n" > /dev/null
    check 1
done

describe "Testowanie braku parametru n"
echo "" | "$SOLUTION" > /dev/null
check 1

describe "Testowanie nadmiarowych parametrów"
echo "" | "$SOLUTION" 69 420 > /dev/null
check 1

describe "Testowanie błędu I/O na wejściu (EBADF)"
"$SOLUTION" 123 0>/dev/null
check 1

describe "Testowanie błędu I/O na wejściu (EISDIR)"
"$SOLUTION" 123 <.
check 1

describe "Testowanie błędu I/O na wyjściu (ENOSPC)"
"$SOLUTION" 3 < "$BASEDIR"/baseline/algae.in > /dev/full
check 1

describe "Testowanie wejścia większego niż dostępny RAM"
yes 'meowmeowmeowmeow' | tr -d '\n' | "$SOLUTION" 123 >/dev/null
check 1

tmpfile="$(mktemp)"
trap "rm $tmpfile" EXIT

# run_correctness $n $infile $outfile
run_correctness() {
    "$SOLUTION" "$1" < $2 > $tmpfile
    check 0 ""
    check_output $tmpfile $3 ""
    clear_status
}

testdir=baseline
for infile in "$BASEDIR"/$testdir/*.in; do
    filename="${infile##*/}"
    testname="${filename%.in}"
    for outfile in "$BASEDIR"/$testdir/$testname.out.*; do
        n="${outfile##*.}"
        show_status "$testdir/$filename n=$n"
        run_correctness "$n" "$infile" "$outfile"
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
    show_status "$testdir/$no_dir id=$id n=$n"
    run_correctness "$n" "$infile" "$outfile"
done

if (( num_failed )); then
    echo -e "${BRED}$num_failed failed checks${NC}"
fi
