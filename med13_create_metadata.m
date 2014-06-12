

function med13_create_metadata
	%med13_create_metadata_devel();
	%med13_create_metadata_3('dev');
	%med13_create_metadata_6();
	%med13_create_metadata_7();
	%med13_create_metadata_3('devel');
	%med13_create_metadata_4('devel', 100000);
	%med13_create_metadata_4('devel', 90);
	med13_create_metadata_4('devel', 10);
end

% genereate new dev videos: only include ps videos + background videos
function med13_create_metadata_6()
	% load ps events
	event_list = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.events.ps.lst';
	fh = fopen(event_list, 'r');
	infos = textscan(fh, '%s %s', 'delimiter', ' >.< ', 'MultipleDelimsAsOne', 1);
	fclose(fh);
	events = infos{1};
	
	list_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/dev/EK130';
	event_set = 'EK130';
	
	event_videos = {};
    pos_only_videos = {};
	for ii=1:length(events),
		event = events{ii};
		ann_file = sprintf('%s/%s.%s.lst', list_dir, event, event_set);
		fprintf('loading event %s...\n', event);
		[pos_videos, miss_videos] = load_ann_event_videos(ann_file);
		this_videos = [pos_videos; miss_videos];
        
		event_videos = [event_videos; this_videos];
        pos_only_videos = [pos_only_videos; pos_videos];
	end
	
	% load background videos
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	bgvideos = load_video_list(f_eventbg_csv);
	
	all_videos = [event_videos; bgvideos'];
    
    % Update Sep 5: there are some overlapped videos...
    all_videos = unique(all_videos);
    
	%write
	f_output  = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.dev.ps.lst';
	fh = fopen(f_output, 'w');
	for ii=1:length(all_videos),
		fprintf(fh, '%s\n', all_videos{ii});
	end
	fclose(fh);
	
end

% genereate new dev videos: only include ah videos + background videos
function med13_create_metadata_7()
	% load ps events
	event_list = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.events.ah.lst';
	fh = fopen(event_list, 'r');
	infos = textscan(fh, '%s %s', 'delimiter', ' >.< ', 'MultipleDelimsAsOne', 1);
	fclose(fh);
	events = infos{1};
	
	list_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/dev/EK130';
	event_set = 'EK130';
	
	event_videos = {};
    pos_only_videos = {};
	for ii=1:length(events),
		event = events{ii};
		ann_file = sprintf('%s/%s.%s.lst', list_dir, event, event_set);
		fprintf('loading event %s...\n', event);
		[pos_videos, miss_videos] = load_ann_event_videos(ann_file);
		this_videos = [pos_videos; miss_videos];
        
		event_videos = [event_videos; this_videos];
        pos_only_videos = [pos_only_videos; pos_videos];
	end
	
	% load background videos
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	%eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	bgvideos = load_video_list(f_eventbg_csv);
	
	all_videos = [event_videos; bgvideos'];
    
    % Update Sep 5: there are some overlapped videos...
    all_videos = unique(all_videos);
    
	%write
	f_output  = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.dev.ah.lst';
	fh = fopen(f_output, 'w');
	for ii=1:length(all_videos),
		fprintf(fh, '%s\n', all_videos{ii});
	end
	fclose(fh);
	
end

% generate metadata for 
function med13_create_metadata_8()
end

function [pos_videos, miss_videos] = load_ann_event_videos(ann_file),
	fh = fopen(ann_file, 'r');
	infos = textscan(fh, '%s %s', 'delimiter', ' >.< ', 'MultipleDelimsAsOne', 1);
	fclose(fh);
	all_videos = infos{1};
	ann_infos = infos{2};
	pos_idx = find(ismember(ann_infos, 'positive'));
	miss_idx = find(ismember(ann_infos, 'miss'));
	pos_videos = all_videos(pos_idx);
	miss_videos = all_videos(miss_idx);
	
end

function med13_create_metadata_4(sz_pat, sec)

	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted.mat', sz_pat);
	
	fprintf('loading metadata..\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	videos = fieldnames(metadata);
	
	output_dir =  sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/segment-%d/%s', sec, sz_pat);
	if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
	
	for ii=1:length(videos),
		video_id = videos{ii};
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		num_frames = metadata.(video_id).num_frames;
		fps = metadata.(video_id).fps;
		
		if sec == 100000,
			seg_length = num_frames;
		else
			seg_length = floor(fps* sec); % frames;
		end
		
		output_file = sprintf('%s/%s.lst', output_dir, video_id);
		fh = fopen(output_file, 'w');
		
		jj = 1;
		while true,
			start_frame = seg_length*(jj-1) + 1;
			end_frame 	= start_frame + seg_length - 1;
			
			if end_frame > num_frames,	
				end_frame = num_frames;
			end
			
			fprintf(fh, '%s.segment_%d.frame%d_%d\n', video_id, jj, start_frame, end_frame);
			jj = jj + 1;
			
			if end_frame == num_frames,
				break;
			end
		end
		fclose(fh);
	end
	
end

% excerpt dev (event + background) from devel
function med13_create_metadata_devel()
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventvideo_csv = 'EVENTS-130Ex_20130405_ClipMD.csv';

	f_eventvideo_csv = fullfile(csv_dir,f_eventvideo_csv);	
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

function med13_create_metadata_3(sz_pat)
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted.mat', sz_pat);
	
	fprintf('loading metadata..\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	videos = fieldnames(metadata);
	
	f_devel_lst = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.%s.lst', sz_pat);
	f_devel_long_lst = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.%s.long.lst', sz_pat);

	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	%f_csv_name = 'EVENTS-130Ex_20130405_ClipMD.csv';
	f_csv_name = 'EVENTS-100Ex_20130913_EventDB.csv';
	f_csv = fullfile(csv_dir, f_csv_name);
	list_video = load_video_list(f_csv);
	
	fh = fopen(f_devel_lst, 'w');
	fh_long = fopen(f_devel_long_lst, 'w');
	for ii=1:length(videos),
		video_id = videos{ii};
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		if metadata.(video_id).num_frames > 80000,
			if isempty(find(ismember(list_video, video_id)))
				fprintf(fh_long, '%s\n', video_id);
			else
				warning('Video %d in event list...\n', video_id);
			end
		else
			fprintf(fh, '%s\n', video_id);
		end
	end
	fclose(fh);
	fclose(fh_long);
	
	
end

function med13_create_metadata_2()
	
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata.mat';
	
	fprintf('Loading metadata...\n');
	load(f_metadata, 'metadata');
	
	meta_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata';
	
	% generating dev metadata
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	
	
	f_csv_name = 'EVENTS-10Ex_20130405_ClipMD.csv';
	f_csv = fullfile(csv_dir, f_csv_name);	
	list_video = load_video_list(f_csv);
	f_metadata_list = fprintf('%s/trecvidmed13.events-10ex.lst', meta_dir);
	
	fprintf('Generating metadata for %s ...\n', f_csv_name);
	fh = fopen(f_metadata_list);	
	for ii=1:length(list_video),
		video_name = list_video{ii};
		fprintf(fh, '%s\n', video_name);
	end
	fclose(fh);
	% generating val metadata

	f_csv_name = 'EVENTS-100Ex_20130405_ClipMD.csv';
	f_csv = fullfile(csv_dir, f_csv_name);	
	list_video = load_video_list(f_csv);
	f_metadata_list = fprintf('%s/trecvidmed13.events-100ex.lst', meta_dir);
	
	fprintf('Generating metadata for %s ...\n', f_csv_name);
	fh = fopen(f_metadata_list);	
	for ii=1:length(list_video),
		video_name = list_video{ii};
		fprintf(fh, '%s\n', video_name);
	end
	fclose(fh);

	f_csv_name = 'EVENTS-130Ex_20130405_ClipMD.csv';
	f_csv = fullfile(csv_dir, f_csv_name);	
	list_video = load_video_list(f_csv);
	f_metadata_list = fprintf('%s/trecvidmed13.events-130ex.lst', meta_dir);
	
	fprintf('Generating metadata for %s ...\n', f_csv_name);
	fh = fopen(f_metadata_list);	
	for ii=1:length(list_video),
		video_name = list_video{ii};
		fprintf(fh, '%s\n', video_name);
	end
	fclose(fh);
	
end

function med13_create_metadata_1()
	
	f_video_lookup = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/video_lookup.mat';
	
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata.mat';
	
	load(f_video_lookup, 'videos');
	
	video_list = fieldnames(videos);
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	
	metadata = struct;
	
	for ii = 1:length(video_list),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
			
		video_id = video_list{ii};
		video_path = sprintf('%s/%s', video_dir, videos.(video_id));	
		[fps, num_frames] = get_number_of_frames(video_path);
		
		metadata.(video_id).fps = fps;
		metadata.(video_id).num_frames = num_frames;
		metadata.(video_id).ldc_pat = videos.(video_id);
	end
	
	fprintf('\nSaving metadata...\n');
	save(f_metadata, 'metadata');
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

