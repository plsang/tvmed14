export LD_LIBRARY_PATH=/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/usr/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/usr/local/lib:/net/per900a/raid0/plsang/usr.local/usrlib:$LD_LIBRARY_PATH
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 101, 200)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 201, 300)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 301, 400)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 401, 500)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 501, 600)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 601, 700)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 701, 800)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 801, 900)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 901, 1000)" &
wait

