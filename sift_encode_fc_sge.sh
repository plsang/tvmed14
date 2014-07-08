# Written by Duy Le - ledduy@ieee.org
# Last update Jun 26, 2012
#!/bin/sh
# Force to use shell sh. Note that #$ is SGE command
#$ -S /bin/sh
# Force to limit hosts running jobs
#$ -q all.q@@bc4hosts
# Log starting time
date 
# for opencv shared lib
export LD_LIBRARY_PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/usr/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/usr/local/lib:/net/per900a/raid0/plsang/usr.local/usrlib:$LD_LIBRARY_PATH
# Log info of the job to output file  *** CHANGED ***
echo [$HOSTNAME] [$JOB_ID] [matlab -nodisplay -r "sift_encode_fc_sge('$1', '$2', '$3', '$4', $5, $6, $7, $8, $9)"]
# change to the code dir  --> NEW!!! *** CHANGED ***
cd /net/per610a/export/das11f/plsang/codes/kaori-secode-med14.1
# Log info of current dir
pwd
# Command - -->  must use " (double quote) for $2 because it contains a string  --- *** CHANGED ***
# LD_PRELOAD="/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so.6" matlab -nodisplay -r "sift_encode_fc_sge( '$1', '$2', '$3', $4, $5 )"
matlab -nodisplay -r "sift_encode_fc_sge('$1', '$2', '$3', '$4', $5, $6, $7, $8, $9)"
# Log ending time
date

