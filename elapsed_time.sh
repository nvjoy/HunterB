#!/bin/bash

# Record start time
start_time=$(date +%s)

# Your script logic goes here
# ...

# Record end time
end_time=$(date +%s)

# Calculate elapsed time in seconds
elapsed_time=$((end_time - start_time))

# Calculate days, hours, minutes, and seconds
days=$((elapsed_time / 86400))
hours=$(( (elapsed_time % 86400) / 3600 ))
minutes=$(( (elapsed_time % 3600) / 60 ))
seconds=$((elapsed_time % 60))

echo "Elapsed time: $days days, $hours hours, $minutes minutes, $seconds seconds"