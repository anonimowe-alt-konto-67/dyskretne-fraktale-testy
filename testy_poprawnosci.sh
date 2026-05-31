if [ $# -eq 0 ]
then
    echo "Poprawne użycie: testy_poprawnosci.sh <ścieżka do pliku binarnego testowanego programu>"
fi

BRED='\033[1;31m'
NC='\033[0m' # No Color

for input_file in testy_poprawnosci_male/*.in
do
    echo $input_file
    no_dir="${input_file##*/}"
    base="${no_dir%.in}"

    n="${base##*_}"
    without_id_text="${base#id_}"
    id="${without_id_text%%_*}"

    $1 $n < $input_file > wyjscie_programu_testowanego.out

    exit_code=$?

    if [ $exit_code -ne 0 ]
    then
        printf "${BRED}Program powinien zwrócić 0, a zwrócił $exit_code.\n${NC}"
        echo "id małego testu poprawnego wejścia:" $id "n:" $n
        break
    fi

    output_file="testy_poprawnosci_male/id_$id.out"

    diff -bw wyjscie_programu_testowanego.out $output_file

    if [ $? -ne 0 ]
    then
        echo "id małego testu poprawnego wejścia:" $id "n:" $n
        printf "${BRED}Program wypisał inne wyjście niż jest wymagane przez test. Wyjście programu można zobaczyć w wyjscie_programu_testowanego.out.\n${NC}"
        break
    fi

done
