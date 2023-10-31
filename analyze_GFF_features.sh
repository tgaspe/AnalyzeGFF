#!/opt/homebrew/bin/bash

if [[ $# -ne 1 ]]; then
	echo "usage:./analyze_GFF_features.sh <chromosomeID>"
	exit 1
fi

if [[ $1 == "MT" ]] || [[ $1 == "X" ]] || [[ $1 == "Y" ]]; then
	echo
elif [[ $1 -ge 1 ]] && [[ $1 -le 23 ]]; then
	echo
else
	echo ${1}$(echo " is not a valid chromosomeID (possible values: 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 MT X Y)")
	exit 1
fi 

echo " --- Starting Program ---"

chromosome=$1

filename="Homo_sapiens.GRCh38.110.chromosome.${chromosome}.gff3.gz"
filename1="Homo_sapiens.GRCh38.110.chromosome.${chromosome}.gff3"

if [ -e $filename ] || [ -e $filename1 ]; then
	echo "File already in directory!"
else
	curl -o $filename https://ftp.ensembl.org/pub/current_gff3/homo_sapiens/$filename
	
	if [ $? -eq 0 ]; then
		echo "Download completed: $filename"
	else
		echo "Download failed"
		exit 1
	fi
	
	echo "Unziping file ..."
	gzip -d $filename
	echo "Unzip completed."

fi

# Counting number of features
n_features=$(cat $filename1 | grep -v '^#' | cut -f3 | sort | uniq | wc -l )
features=$(cat $filename1 | grep -v '^#' | cut -f3 | sort | uniq)

echo
echo "Feature count chromosome ${chromosome}: ${n_features}"
echo -------------------------------------------------

for feat in $features; do
	n_feat=$( cat $filename1 | grep "$feat" | wc -l )
	echo "${n_feat} ${feat}"
done
echo -------------------------------------------------
echo
echo "Top 10: chromosome: ${chromosome}"
echo -------------------------------------------------
# echo ">>>transcriptsIDs with the highest number of exon "

# # Retriving each unique transcript
# transcripts=$( cat $filename1 | grep -v "ID=" | grep "exon" | cut -f9 | cut -b 19-33 | sort | uniq )

# # Retriving all exon lines
# exons=$( cat $filename1 | grep -v "ID=" | grep "exon" | cut -f9 | cut -b 19-33 | sort )

# # Creating a dictionary with every transcriptID as the key
# declare -A transcriptDict

# # Initialiazing every value to zero
# for id in $transcripts; do
# 	#echo $id
# 	transcriptDict["$id"]=0
# done

# # Calculating number of exons per transcript
# for t in $transcripts; do
#     n_exons=0
#     is_same=0  # Initialize is_same to 0
    
#     # Loop through each exon
#     for exon in $exons; do
#         if [[ "$exon" == "$t" ]]; then
#             # If the exon matches the current transcript, increment the exon count
#             	n_exons=$((n_exons + 1))
#             	is_same=1
#         elif [[ "$is_same" -eq 1 ]]; then
#             	break
#         fi
#     done

#     # Add the count to the associative array
#     transcriptDict["$t"]=$n_exons

# done


# # Array to store transcript and n_of_occurences
# key_value=()

# for key in "${!transcriptDict[@]}"; do
# 	key_value+=("$key:${transcriptDict[$key]}")
# done

# # Sort key value array
# sorted_key_value=(
# 	$(
# 		for item in "${key_value[@]}"; do 
# 			echo "$item";
# 		done | sort -t: -k2,2nr
# 	)
# )

# for value in "${sorted_key_value[@]:0:10}"; do
# 	trans=${value%%:*}
# 	n_feature=${value#*:}
# 	echo "Transcript ${trans}>>> #exon:${n_feature}	gene..."
# done

echo --------- With Top 10 function ---------

# -----  Function Top 10 ------
top_10() {

	# Declaring local variables
	local feature=$1
	local count=$2

	echo ">>>transcriptsIDs with the highest number of ${feature}"

	# Retriving each unique transcript
	transcripts=$( cat $filename1 | grep -v "ID=" | grep $feature | cut -f9 | cut -b 19-33 | sort | uniq )

	echo "this command takes to long!"

	# Retriving all feature lines and cutting just the id 
	#lines=$( cat $filename1 | grep -v "ID=" | grep $feature | cut -f9 | cut -b 19-33 | sort )
	lines1=($( cat $filename1 | grep -v "ID=" | grep $feature | cut -f9 | cut -b 19-33 | sort ))  # Array Version

	echo "size lines1: ${#lines1}"

	# Creating a dictionary with every transcriptID as the key
	declare -A transcriptDict

	# Initialiazing every value to zero
	# for id in $transcripts; do
	# 	transcriptDict["$id"]=0
	# done



	# Calculating number of exons per transcript

	# Another solution 
	for element in "${lines1[@]}"; do
		# Check if the element exists in the counts array
		if [ -v transcriptDict["$element"] ]; then
			# Increment the count
			((transcriptDict["$element"]++))
		else
			# Initialize the count to 1 for a new element
			transcriptDict["$element"]=1
		fi
	done

	# # Display the counts
	# for element in "${!counts[@]}"; do
	# 	echo "$element: ${counts["$element"]} occurrences"
	# done

# 	current_index=0
# 	for t in $transcripts; do
# 		n_feat=0
# 		is_same=0  					# Initialize is_same to 0
# 		index=$((current_index))	# Updates index to latest index

# 		for index in "${!lines1[@]}"; do
# 			if [[ "${lines1[$index]}" == "$t" ]]; then   # feature matches the current transcript, increment the count
# 				n_feat=$((n_feat + 1))
# 				is_same=1
# 			elif [[ "$is_same" -eq 1 ]]; then
# 				# Save the index and for the next one continue from that index
# 				echo "curr_index: ${current_index} --- index: ${index}"
# 				current_index=$((index))
# 				break
# 			fi
# 		done
		
# 		# Another solution (dont know which one is more efficient)
# #		n_feat=$(echo $lines | grep -o $t | wc -l )

# 		# Add the count to the dicionary
# 		transcriptDict[$t]=$((n_feat))

# 	done

	# Array to store transcript and n_of_occurences
	key_value=()

	for key in "${!transcriptDict[@]}"; do
		key_value+=("$key:${transcriptDict[$key]}")
	done

	# Sort key value array
	sorted_key_value=(
		$(
			for item in "${key_value[@]}"; do 
				echo "$item";
			done | sort -t: -k2,2nr
		)
	)

	for value in "${sorted_key_value[@]:0:${count}}"; do
		trans=${value%%:*}
		n_feature=${value#*:}

		# I need to retrive the gene ID and its description from the internet

		echo "Transcript ${trans}>>> #${feature}:${n_feature} gene: id + description"
	done

	echo

	# Print the results
	#for key in "${!transcriptDict[@]}"; do
	#    echo "Transcript: $key, Number of Exons: ${transcriptDict[$key]}"
	#done

	#for key in "${!sorted_key_value[@]}"; do
	#	echo "key: ${key}  value: ${sorted_key_value[$key]}"
	#done

}

# Binary search function
#binary_search() {
#    local arr=("$@")  # Convert arguments to an array
#    local string=$1
#	local number="${string//[!0-9]/}"
#	local target=$((10#$number))
#   local left=0
#    local right=$((${#arr[@]} - 1))

#    while [ $left -le $right ]; do
#        local mid=$((left + (right - left) / 2))
#		arr_mid="${arr[mid]//[!0-9]/}"
#		arr_mid_int=$((10#$number)) 

#       if [ "${arr_mid_int}" -eq "$target" ]; then
#            result=$mid  # Update result if a match is found
#            right=$((mid - 1))  # Continue searching in the left half
#        elif [ "${arr_mid_int}" -lt "$target" ]; then
#            left=$((mid + 1))
#       else
#            right=$((mid - 1))
#        fi
#    done

#    echo $result
#}



top_10 "exon" 10
top_10 "five_prime_UTR" 10
top_10 "three_prime_UTR" 10

echo "Finished."

exit 0
