#!/bin/bash

while true; do # Ask for the target IP or hostname from the user and validate it
    read -p "Enter the target IP or hostname: " target

    # Check if the user input is a valid IP address or hostname format
    if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$target" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]+$ ]]; then
        break # Break out of the loop
    else
        echo "Invalid IP or hostname format. Try 192.168.0.1 or google.com"
    fi
done

nmap_output=$(nmap -sV -A $target) # Run nmap to get the detailed version information about the target

echo "Port      State       Service       Version"
echo "-------------------------------------------"

counter=1 # Counter for the number of open ports
entries=() # Create an array to store port and version

while IFS= read -r line; do # Process each line of the nmap_output
    if [[ $line =~ ^[0-9]+/ ]]; then
        port=$(echo "$line" | awk '{print $1}') # Extract the first field from the line
        state=$(echo "$line" | awk '{print $2}') # Extract the second field from the line
        service=$(echo "$line" | awk '{print $3}') # Extract the thrid field from the line
        version=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//') # Extract the version by removing the first 3 fields and spaces in the begining of the string
        if [[ -z "$version" ]]; then # If version field is empty display "unknown"
            version="unknown"
            else
            versions+=("$version") # Collect non-empty versions in the array
        fi
        
        printf "%-10s%-12s%-14s%s\n" "$port" "$state" "$service" "$version" # Display the formatted output with a fixed width for port, state, service, and version
        counter=$((counter + 1)) # Increase the counter for each entry
        if [[ "$version" != "unknown" ]]; then # Check if version entry is not "unknown"
            entries+=("$port $version") # If the version is not "unknown", add the combination of port and version to the 'entries' array
        fi
    fi
done <<< "$nmap_output"

echo " "

count=1 # Counter for entries

while true; do
    read -p "Do you want to view available port version vulnerabilities? (yes/no):" choice
    
    echo " "

    if [ "${choice,,}" == "y" ] || [ "${choice,,}" == "yes" ]; then # If user select is y or yes run the following codes

        echo "Counter   Port      Version"
        echo "---------------------------"
        
        for x in "${entries[@]}"; do # Go through all the available entries
            if [[ $x =~ ^[0-9]+/ ]]; then # Check if the entry starts with a number followed by a forward slash e.g. 22/
                port=$(echo "$x" | awk '{print $1}') # extract the port from the first field
                version=$(echo "$x" | awk '{$1=""; print $0}' | sed 's/^ *//') # Extract the version by removing the port and any leading white spaces
                printf "%-10s%-10s%s\n" "$count)" "$port" "$version" # Display the formatted output with a fixed width for counter, port, and version
                count=$((count + 1)) # Increase the counter for each entry
            fi
        done

        while true; do
            echo " "
            read -p "Enter the counter number to view the version vulnerabilities (q to exit): " select
            
            # Check if the user input is a valid number between 1 and the number of entries
            if [[ "$select" =~ ^[0-9]+$ && "$select" -ge 1 && "$select" -le ${#entries[@]} ]]; then
                selentry=${entries[$((select - 1))]} # Get entry from the selected number
                selver=${selentry#* } # Get the version part of the selected entry by removing the port and white space
                trimmedver=$(echo "$selver" | sed -E 's/([a-zA-Z0-9.-]+\s[0-9]+\.[0-9]+[^ ]*).*/\1/') # Remove everything from the input string apart from the version number
                echo "Searching for exploits related to $selver..."
                
                echo " "

                exploit_output=$(searchsploit -t --id $trimmedver) # Run searchsploit on the selected version and capture the output
                
                # Check if there are no known possible vulnerabilities for the selected version
                if [[ "$exploit_output" == *"Exploits: No Results"* && "$exploit_output" == *"Shellcodes: No Results"* ]]; then
                    echo "No known possible vulnerabilities for $selver"
                else
                    # If there are known possible vulnerabilities, display them
                    echo "Exploits related to $selver:"
                    echo "$exploit_output" # Display searchsploit output
                fi

            elif [ "${select,,}" == "q" ] || [ "${select,,}" == "quit" ] ||  [ "${select,,}" == "exit" ]; then # If user select is n or no exit out of the script
                echo "Exiting..."
                exit 0

            else
                echo "Invalid counter number selected." # Propmt user if input selected number is greater than the number of entries
            fi
        done


    elif [ "${choice,,}" == "n" ] || [ "${choice,,}" == "no" ]; then # If user input is n or no exit out of the script
        exit 0
    else
        echo "Incorrect input. Please enter yes or no" # Prompt user that input is not correct
    fi

done