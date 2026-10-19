
printf -v alphabet '%s' {a..z}

options=":${alphabet//i/i:}"
options="${options//o/o:}"

while getopts "$options" opt; do
    case $opt in
    
    
    
    esac
done
