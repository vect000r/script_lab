printf -v alphabet '%s' {a..z}

options=":${alphabet//i/i:}"
options="${options//o/o:}"

while getopts "$options" opt; do
    case $opt in
        i|o)  if [[ -z "$OPTARG" ]]; then
                  printf -- '-%s requires a filename\n' "$opt" >&2
                  exit 2
              fi
              printf '%s present and set to %s\n' "-$opt" "$OPTARG" ;;
        q)    printf 'Unsupported option: %s\n' "$opt" ;;
        [a-h]) printf '%s present\n' "-$opt" ;;
        [a-z]) printf '%s present\n' "-$opt" ;;
        \?)   printf 'Unknown option: -%s\n' "$OPTARG" >&2; exit 1 ;;
        :)    printf 'Option -%s requires an argument\n' "$OPTARG" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

printf 'Arguments are:\n'
for (( idx=1; idx<=$#; idx++ )); do
    printf '$%s=%s\n' "$idx" "${!idx}"
done   