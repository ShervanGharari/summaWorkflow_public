# GDAL doc: https://gdal.org/programs/gdalwarp.html
# MODIS doc: https://lpdaac.usgs.gov/documents/101/MCD12_User_Guide_V6.pdf

# Extract the modeling domain out of the global-cover VRTs.

# load the module
module load nixpkgs/16.09  gcc/5.4.0 gdal/2.1.3


#---------------------------------
# Specify settings
#---------------------------------

# --- Location of source VRT data
dest_line=$(grep -m 1 "^parameter_land_vrt2_path" ../../../0_control_files/control_active.txt) # full settings line
source_path=$(echo ${dest_line##*|})   # removing the leading text up to '|'
source_path=$(echo ${source_path%%#*}) # removing the trailing comments, if any are present

# Specify the default path if needed
if [ "$source_path" = "default" ]; then
  
 # Get the root path and append the appropriate install directories
 root_line=$(grep -m 1 "^root_path" ../../../0_control_files/control_active.txt)
 root_path=$(echo ${root_line##*|}) 
 root_path=$(echo ${root_path%%#*})

 # domain name
 domain_line==$(grep -m 1 "^domain_name" ../../../0_control_files/control_active.txt)
 domain_name=$(echo ${domain_line##*|}) 
 domain_name=$(echo ${domain_name%%#*})
 
 # source path
 source_path="${root_path}/domain_${domain_name}/parameters/landclass/3_vrt_epsg_4326"

fi

# --- Location where cropped VRT needs to go
dest_line=$(grep -m 1 "^parameter_land_vrt3_path" ../../../0_control_files/control_active.txt) # full settings line
dest_path=$(echo ${dest_line##*|})   # removing the leading text up to '|'
dest_path=$(echo ${dest_path%%#*}) # removing the trailing comments, if any are present

# Specify the default path if needed
if [ "$dest_path" = "default" ]; then
  
 # Get the root path and append the appropriate install directories
 root_line=$(grep -m 1 "^root_path" ../../../0_control_files/control_active.txt)
 root_path=$(echo ${root_line##*|}) 
 root_path=$(echo ${root_path%%#*})

 # domain name
 domain_line==$(grep -m 1 "^domain_name" ../../../0_control_files/control_active.txt)
 domain_name=$(echo ${domain_line##*|}) 
 domain_name=$(echo ${domain_name%%#*})
 
 # destination path
 dest_path="${root_path}/domain_${domain_name}/parameters/landclass/4_domain_vrt_epsg_4326"
fi

# Make destination directory 
mkdir -p $dest_path

# --- Find dimensions of modeling domain
domain_line=$(grep -m 1 "^forcing_raw_space" ../../../0_control_files/control_active.txt) # full settings line
domain_full=$(echo ${domain_line##*|})   # removing the leading text up to '|'
domain_full=$(echo ${domain_full%%#*}) # removing the trailing comments, if any are present

# Separate the values into an array
while IFS='/' read -ra domain_array; do
 LAT_MAX=${domain_array[0]}
 LON_MIN=${domain_array[1]}
 LAT_MIN=${domain_array[2]}
 LON_MAX=${domain_array[3]}
done <<< "$domain_full"


#---------------------------------
# Crop the domain
#---------------------------------

# Loop over all files
for FILE_SRC in $source_path/MCD*.vrt
do

	# Extract the filename
	FILENAME=$(basename -- $FILE_SRC)

	# construct the destination file
	FILE_DES=$dest_path/"domain_"$FILENAME

	# Do the cut out
	gdal_translate -of VRT -projwin $LON_MIN $LAT_MAX $LON_MAX $LAT_MIN $FILE_SRC $FILE_DES

done


#---------------------------------
# Code provenance
#---------------------------------
# Generates a basic log file in the domain folder and copies the control file and itself there.
# Make a log directory if it doesn't exist
log_path="${dest_path}/_workflow_log"
mkdir -p $log_path

# Log filename
today=`date '+%F'`
log_file="${today}_specify_subdomain_log.txt"

# Make the log
this_file='specify_subdomain.sh'
echo "Log generated by ${this_file} on `date '+%F %H:%M:%S'`"  > $log_path/$log_file # 1st line, store in new file
echo 'Cropped VRTs to modeling domain.' >> $log_path/$log_file # 2nd line, append to existing file

# Copy this file to log directory
cp $this_file $log_path







