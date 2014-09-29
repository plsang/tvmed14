export LD_LIBRARY_PATH=/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/usr/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/usr/local/lib:/net/per900a/raid0/plsang/usr.local/usrlib:$LD_LIBRARY_PATH
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 1, 10)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 11, 20)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 21, 30)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 31, 40)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 41, 50)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 51, 60)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 61, 70)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 71, 80)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 81, 90)" &
matlab -nodisplay -r "densetraj_encode_ldc('video-bg', 91, 100)" &
wait

