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


# -----  Function Top 10 ------
top_10() {

	# Declaring local variables
	local feature=$1
	local count=$2

	echo ">>>transcriptsIDs with the highest number of ${feature}"

	# Retriving each unique transcript
	transcripts=$( cat $filename1 | grep -v "ID=" | grep $feature | cut -f9 | cut -b 19-33 | sort | uniq )

	# Retriving all feature lines and cutting just the id 
	lines=($( cat $filename1 | grep -v "ID=" | grep $feature | cut -f9 | cut -b 19-33 | sort ))

	# Creating a dictionary with every transcriptID as the key
	declare -A transcriptDict

	# Calculating number of feature per transcript
	for id in "${lines[@]}"; do
		# Check if the element exists in the dictionary
		if [ -v transcriptDict["$id"] ]; then
			# Increment the count
			((transcriptDict["$id"]++))
		else
			# Initialize the count to 1 for a new element
			transcriptDict["$id"]=1
		fi
	done

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
		
		transcript_id=${value%%:*}
		n_feature=${value#*:}

		# Retriving parent gene ID
		url="https://rest.ensembl.org/lookup/id/${transcript_id}?content-type=application/json"
		response=$(curl -s "$url")
		parent_id=$(echo "$response" | jq -r '.Parent')
		
		# Retriving gene description
		url2="https://rest.ensembl.org/lookup/id/${parent_id}?content-type=application/json"
		response2=$(curl -s "$url2")
		description=$(echo "$response2" | jq -r '.description')

		echo "Transcript ${transcript_id}>>> #${feature}:${n_feature}	gene:${parent_id}	${description}"
	done

	echo
}

top_10 "exon" 10
top_10 "five_prime_UTR" 10
top_10 "three_prime_UTR" 10

echo "Finished."

exit 0
