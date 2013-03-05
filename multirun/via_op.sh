#!/bin/bash


#VALUES
#Ns=(1 2 16 128 512 1024 2048 4096 8192 14654 16384)
#NBs=(32 64 96 128 160 192 224 256)
Ns=(4 16 64 256 1024 2048 4096 6144 8192)
NBs=(8 16 32 64 96 128 160 192 224 256)
P=1
Q=2
PnQ=$(echo "${P}""*""${Q}" | bc)
COUNTER=0

TEMP_FILE=/tmp/out.txt
DATE_STAMP=$(date '+%m%d%H%M%S')
DEBUG_FILE=debug"$DATE_STAMP".log
TSV_FILE=gflops"$DATE_STAMP".tsv

TESTs=(l2_rqsts l2_lines_in LLC_MISSES LLC_REFS)
SAMPLEs=(200000:0x01 100000:0x07 6000 6000)

OUT_FILEs=()
RESULTs=()


#FUNCTIONS
get_time_string () {
    TIME_STRING="$(date '+%H:%M:%S')"
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


print_status1 () {
    COUNTER=$[$COUNTER + 1]
    get_time_string
    printf "\b\b\b\b\b\b"
    if [ "$COUNTER" -ne "$TOTAL_TEST" ]; then
        printf "%5.2f%%" $(echo "scale=2;100*""$COUNTER""/""$TOTAL_TEST" | bc)
    else
        printf "Completed."
    fi
}

print_status () {
    COUNTER=$[$COUNTER + 1]
    get_time_string
    printf "\nTest %d (N=%d, NB=%d) finished at %s" \
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
    mpiexec -n "$PnQ" ./xhpl HPL.dat
}


save_result () {
    GFLOPS=$(awk '/^WR/{print $7}' HPL.out)
    printf "%d\t%d\t%s\n" "${Ns[$INDEX_N]}" "${NBs[$INDEX_NB]}" "${GFLOPS}" >> "$TSV_FILE"

    # Retrieve Oprofile data and give up unsuitable results
    opreport xhpl > "$TEMP_FILE"
    ABANDON=0
    RESULTs=()
    for ((INDEX_T = 0, INDEX = 1; INDEX_T < ${#TESTs[*]}; INDEX_T += 1, INDEX += 2))
    do
        RESULT=$(awk '/xhpl/{print $'"$INDEX"'}' "$TEMP_FILE" | grep '^[0-9.]')
        if [ -z "$RESULT" ]; then
            ABANDON=1
            break
        fi
        RESULTs[$INDEX_T]="$RESULT"
    done

    # Save results to file
    for ((INDEX_T = 0; INDEX_T < ${#TESTs[*]}; INDEX_T += 1))
    do
        if [ "$ABANDON" -eq 1 ]; then
            RESULT=0
        else
            RESULT="${RESULTs[$INDEX_T]}"
        fi
        printf "%d\t%d\t%s\n" "${Ns[$INDEX_N]}" "${NBs[$INDEX_NB]}" "${RESULT}" >> "${OUT_FILEs[$INDEX_T]}"
    done

    # Confirm the order
    fgrep LLC_REFS: "$TEMP_FILE" >> "$DEBUG_FILE"
}


clean_end () {
    rm -f "$TEMP_FILE"
    opcontrol --shutdown
    printf "\nAll done!\n"
}


make_event_command() {
    # Output file names 
    for ((INDEX_T = 0; INDEX_T < ${#TESTs[*]}; INDEX_T += 1))
    do
        OUT_FILEs[$INDEX_T]="${TESTs[$INDEX_T]}""$DATE_STAMP".tsv
    done

    # OProfile event setting command to execute
    OP_COMMAND="opcontrol "
    for ((INDEX_T = 0; INDEX_T < ${#TESTs[*]}; INDEX_T += 1))
    do
        OP_COMMAND+=" --event=""${TESTs[$INDEX_T]}"":""${SAMPLEs[$INDEX_T]}"" "
    done
    OP_COMMAND+="--no-vmlinux"

    # Set OProfile event
    ${OP_COMMAND}
}


start_oprofile () {
    opcontrol --reset
    opcontrol --start
}


stop_oprofile () {
    opcontrol --stop
}


#MAIN
clear
rm -f "$DEBUG_FILE"

print_hello
make_event_command
opcontrol --init
printf "#Ns\tNBs\tGFLOPS\n" > "$TSV_FILE"

for ((INDEX_N = 0; INDEX_N < ${#Ns[*]}; INDEX_N += 1))
do
    for ((INDEX_NB = 0; INDEX_NB < ${#NBs[*]}; INDEX_NB += 1))
    do
        make_hpl_dat
        start_oprofile
        run_test
        stop_oprofile
        save_result
        print_status
    done
done

clean_end

exit 0
