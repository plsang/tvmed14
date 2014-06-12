
err_dir='/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/fps-error-ldc2012e26';
list = dir(err_dir);

f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test.mat');
	
fprintf('loading metadata..\n');
load(f_metadata, 'metadata');

kf_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/keyframes';

tmp_dir  = '/net/per610a/export/das11f/plsang/trecvidmed13/tmp';

ldc_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';

for ii = 1:length(list),
	file_name = list(ii).name;
	if strcmp(file_name, '.') || strcmp(file_name, '..'),
		continue;	
	end
	
	video_id = file_name(1:end-4);
	
	ldc_pat = metadata.(video_id).ldc_pat;
	
	kf_video_dir = fullfile(kf_dir, ldc_pat);
	kf_video_dir = kf_video_dir(1:end-4);
	
	% moving error dir to dest 
	cmd = sprintf('mv %s %s', kf_video_dir, tmp_dir);
	
	fprintf('Moving %s...\n', cmd);
	system(cmd)
	
	% making dir
	mkdir(kf_video_dir);
		
	% extracting keyframe again for this video
	video_file = fullfile(ldc_dir, ldc_pat);
	cmd = sprintf('/net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i %s -r 0.5 %s/%s-%%6d.jpg', video_file, kf_video_dir, video_id);
	system(cmd);
end


