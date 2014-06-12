function [fps, num_frames] = med13_metadata_patch

f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata.mat';

f_metadata_tmp = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_tmp.mat';

load(f_metadata, 'metadata');

videos = fieldnames(metadata);

root_ldc = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
tmp_dest_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/fps-error-tmp/';
from_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/fps-error/';

count = 0;
fps = []
num_frames = [];
for ii = 1:length(videos),
	fps(end+1) = metadata.(videos{ii}).fps;
	num_frames(end+1) = metadata.(videos{ii}).num_frames;	
end


end

function [fps, num_frames] = get_number_of_frames(filepath)
	
	ffmpeg_bin = '/net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg';
	
	% explantions:
	% 2 --> file descriptor of stderr,
	% 1 --> file descriptor of stdout, (0 is file descriptor of stdin)
	% > means redirect stream
	% & indicates that what follows a file descriptor, not a filename
	% note: escape \ by \\

	%%% example 1, with duplicate outputs
	%%% /net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i /net/per900a/raid0/plsang/dataset/MED10/HVC1035.mp4 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p"
	%%% example 2, with one output, using sed '0,/pattern/s/pattern/replacement/' filename
	%%% /net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i /net/per900a/raid0/plsang/dataset/MED10/HVC1035.mp4 2>&1 | sed -n "0,/.*, \(.*\) fps.*/s/.*, \(.*\) fps.*/\1/p"
	
	cmd_fps = sprintf('%s -i %s 2>&1 | sed -n "0,/.*, \\(.*\\) fps.*/s/.*, \\(.*\\) fps.*/\\1/p"', ffmpeg_bin, filepath);
	[~, fps] = system(cmd_fps);	
	
	% get duration
	cmd = sprintf('%s -i %s 2>&1 | sed -n "s/.*Duration: \\([^,]*\\), .*/\\1/p"', ffmpeg_bin, filepath);
	[~, duration] = system(cmd);

	fps = str2num(strtrim(fps));
	duration = strtrim(duration);
	
	if fps > 50,
		msg = sprintf('FPS > 50 [%s]', cmd);
		warning(msg);
		log(msg);
	end
	
	splits = regexp(duration, ':', 'split');
	if isempty(fps) || length(splits) ~= 3,
		%num_frames =  0;
		%return;
		num_frames = 0;
		msg = sprintf('Empty FPS or Unknown duration format [%s] when running cmd [%s]', duration, cmd);
		warning(msg);
		log(msg);
		return;
	end
	
	h = str2num(strtrim(splits{1}));
	m = str2num(strtrim(splits{2}));
	s = str2num(strtrim(splits{3}));

	total_seconds = 3600 * h + 60 * m + s;

	num_frames = floor(total_seconds * fps);
	
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/med13_create_metadata.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

