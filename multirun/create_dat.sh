#!/bin/bash


#VALUES
Ns=(1 2 16 128 512 1024 2048 4096 8192 14654 16384)
NBs=(32 64 96 128 160 192 224 256)
P=1
Q=2
COUNTER=0
TSV_FILE=gflops.tsv

#FUNCTIONS
get_time_string () {
    TIME_STRING="$(date '+%H:%M:%S %A %B %d %Y')"
}


print_hello () {
    get_time_string
    printf "Search Started at %s\n" "$TIME_STRING"

    printf "Ns = "
    for ((INDEX_N = 0; INDEX_N < ${#Ns[*]}; INDEX_N += 1))
    do
        printf "%d " "${Ns[$INDEX_N]}"
    done

    printf "\nNBs = "
    for ((INDEX_NB = 0; INDEX_NB < ${#NBs[*]}; INDEX_NB += 1))
    do
        printf "%d " "${NBs[$INDEX_NB]}"
    done

    TOTAL_TEST=$(echo "${#Ns[*]}""*""${#NBs[*]}" | bc)
    printf "\nTotal: %d Ns, %d NBs, and %d tests.\n" \
            "${#Ns[*]}" "${#NBs[*]}" "${TOTAL_TEST}"
    printf "Now Tests Start."
}


print_status () {
    COUNTER=$[$COUNTER + 1]
    get_time_string
    printf "\b\b\b\b\b\b"
    if [ "$COUNTER" -ne "$TOTAL_TEST" ]; then
        printf "%5.2f%%" $(echo "scale=2;100*""$COUNTER""/""$TOTAL_TEST" | bc)
    else
        printf "Completed.\n"
    fi
}

print_status2 () {
    COUNTER=$[$COUNTER + 1]
    get_time_string
    printf "Test %d (N=%d, NB=%d) finished at %s\n" \
            "$COUNTER" "${Ns[$INDEX_N]}" "${NBs[$INDEX_NB]}" "$TIME_STRING"
}


make_hpl_dat () {
    sed -e "s/{N}/""${Ns[$INDEX_N]}""/g" \
        -e "s/{NB}/""${NBs[$INDEX_NB]}""/g" \
        -e "s/{P}/""$P""/g" \
        -e "s/{Q}/""$Q""/g" \
        HPL_model.dat > HPL.dat
}


run_test () {
    mpiexec -n 2 ./xhpl HPL.dat
}


save_result () {
    GFLOPS=$(awk '/^WR/{print $7}' HPL.out)
    printf "%d\t%d\t%s\n" "${Ns[$INDEX_N]}" "${NBs[$INDEX_NB]}" "${GFLOPS}" >> "$TSV_FILE"
}


draw_mountain () {
    printf "Mountain Drawed.\n"
}

#MAIN
clear
print_hello
sleep 1

printf "#Ns\tNBs\tGFLOPS\n" > "$TSV_FILE"

for ((INDEX_N = 0; INDEX_N < ${#Ns[*]}; INDEX_N += 1))
do
    for ((INDEX_NB = 0; INDEX_NB < ${#NBs[*]}; INDEX_NB += 1))
    do
        make_hpl_dat
        run_test
        save_result
        print_status
    done
done

draw_mountain

exit 0

