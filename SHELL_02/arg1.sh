
printf -v alphabet '%s' {a..z}

options=":${alphabet//i/i:}"
options="${options//o/o:}"

while getopts "$options" opt; do
    case $opt in
        i|o)        printf '%s: Value needed!\n' "$opt" ;;
        q)          printf '%s: This flag is not allowed!\n' "$opt" ;;
        [a-h])      printf '%s: Flag from range a-h.\n' "$opt" ;;
        [a-z])      printf '%s: Flag from range a-z.\n' "$opt" ;;
        *)          printf '%s: Other text. \n' "$opt" ;; 
    esac
done
