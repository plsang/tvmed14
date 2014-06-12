function med13_gen_metadata()
	med13_gen_devel_metadata();
	med13_gen_sorted_devel_metadata();
	%med13_create_metadata_dev();
end


function med13_gen_devel_metadata()
	
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
	
	videos = load_lookup_table();
	
	video_list = fieldnames(videos);
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	
	metadata = struct;
	
	f_old_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel--noah.mat';
	old_metadata = load(f_old_metadata, 'metadata');
	old_metadata = old_metadata.metadata;

	for ii = 1:length(video_list),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		video_id = video_list{ii};
		
		if isfield(old_metadata, video_id),
			metadata.(video_id).fps = old_metadata.(video_id).fps;
			metadata.(video_id).num_frames = old_metadata.(video_id).num_frames;
			metadata.(video_id).ldc_pat = old_metadata.(video_id).ldc_pat;
		else
			video_path = sprintf('%s/%s', video_dir, videos.(video_id));	
			[fps, num_frames] = get_number_of_frames(video_path);
			
			metadata.(video_id).fps = fps;
			metadata.(video_id).num_frames = num_frames;
			metadata.(video_id).ldc_pat = videos.(video_id);
		end
	end
	
	fprintf('\nSaving metadata...\n');
	save(f_metadata, 'metadata');
end

function med13_gen_sorted_devel_metadata()

	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
	
	fprintf('Loading metadata...\n');
	load(f_metadata, 'metadata');
	
	videos = fieldnames(metadata);
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	
	list_num_frames = zeros(length(videos), 1);
	
	fprintf('%d videos loaded...\n', length(videos));
	
	for ii = 1:length(videos),
	
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		video_id = videos{ii};
		
		video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		
		if ~exist(video_file, 'file'),
			error('File [%s] does not exist!\n', video_file);
		end
		
		if metadata.(video_id).fps > 50,
			error('FPS too high [%s-%f]!\n', video_id, metadata.(video_id).fps);
		end
		
		list_num_frames(ii) = metadata.(video_id).num_frames;
	end
	
	[sorted_list, sort_idx] = sort(list_num_frames, 'descend');
	
	fprintf('Generating sorted metadata...\n');
	sorted_metadata = struct;
	for ii = 1:length(sort_idx),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		video_idx = sort_idx(ii);
		video_id = videos{video_idx};
		
		sorted_metadata.(video_id).fps = metadata.(video_id).fps;
		sorted_metadata.(video_id).num_frames = metadata.(video_id).num_frames;
		sorted_metadata.(video_id).ldc_pat = metadata.(video_id).ldc_pat;	
	end
	
	
	f_sorted_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel_sorted.mat';
	save(f_sorted_metadata, 'metadata');
	
end


% excerpt dev (event + background) from devel
function med13_create_metadata_dev()
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventvideo_csv = 'EVENTS-100Ex_20130913_ClipMD.csv';

	f_eventvideo_csv = fullfile(csv_dir, f_eventvideo_csv);	
	f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	
	list_eventvideo = load_video_list(f_eventvideo_csv);
	list_bgvideo = load_video_list(f_eventbg_csv);
	
	list_video = [list_eventvideo, list_bgvideo];
	
	% no sort
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');
	fprintf('Loading basic metadata...\n');
	devel_metadata = load(f_metadata, 'metadata');
	devel_metadata = devel_metadata.metadata;
	
	metadata = struct;
	
	videos = fieldnames(devel_metadata);
	
	fprintf('Generating dev...\n');
	for ii=1:length(videos),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		video_id = videos{ii};
		
		if any(ismember(list_video, video_id)),
			metadata.(video_id).fps = devel_metadata.(video_id).fps;
			metadata.(video_id).num_frames = devel_metadata.(video_id).num_frames;
			metadata.(video_id).ldc_pat = devel_metadata.(video_id).ldc_pat;
		end
	end
		
	f_output = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_dev.mat');
	save(f_output, 'metadata');
	
	% sorted
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel_sorted');
	devel_metadata = load(f_metadata, 'sorted_metadata');
	devel_metadata = devel_metadata.sorted_metadata;
	
	metadata = struct;
	videos = fieldnames(devel_metadata);
	
	fprintf('Generating sorted dev...\n');
	for ii=1:length(videos),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		video_id = videos{ii};
		if any(ismember(list_video, video_id)),
			metadata.(video_id).fps = devel_metadata.(video_id).fps;
			metadata.(video_id).num_frames = devel_metadata.(video_id).num_frames;
			metadata.(video_id).ldc_pat = devel_metadata.(video_id).ldc_pat;
		end
	end
		
	f_output = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_dev_sorted.mat');
	save(f_output, 'metadata');
	
end


function videos = load_lookup_table()


	f_clip_lookup = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/doc/clip_location_lookup_table.csv';

	fh = fopen(f_clip_lookup, 'r');

	fprintf('Loading lookup table...\n');

	c_lookup = textscan(fh, '%s %s %s %s', 'delimiter', ',');

	fclose(fh);

	clips = c_lookup{1};
	disks = c_lookup{3};
	paths = c_lookup{4};


	rsz_vid_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';

	clip_ext = '.mp4';
	clip_prefix = 'HVC';

	videos = struct;
	
	for ii = 2:length(clips),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		clip = str2num(strtrim(strrep(clips{ii}, '"', '')));
		disk = strtrim(strrep(disks{ii}, '"', ''));
		path = strtrim(strrep(paths{ii}, '"', ''));
		
		clip_name = sprintf('%s%06d', clip_prefix, clip);
		clip_rel_path = fullfile(disk, path, [clip_name, '.mp4']);
		
		clip_org_path = fullfile(rsz_vid_dir, clip_rel_path);
		if ~exist(clip_org_path, 'file'),
			warning('File %s does not exist! skipped\n', clip_org_path);
			continue;
		end
		
		videos.(clip_name) = clip_rel_path;
		
	end
	
	fprintf('\n');

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
		%log(msg);
		return;
	end
	
	h = str2num(strtrim(splits{1}));
	m = str2num(strtrim(splits{2}));
	s = str2num(strtrim(splits{3}));

	total_seconds = 3600 * h + 60 * m + s;

	num_frames = floor(total_seconds * fps);
	
end
