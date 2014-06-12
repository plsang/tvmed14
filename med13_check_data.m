
function med13_check_data
	
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test.mat');
	
	fprintf('Loading test metadata...\n');
	load(f_metadata, 'metadata');
	
	videos = fieldnames(metadata);
	
	fprintf('Updating ldc pat...\n');
	
	for ii = 1:length(videos),
        
        
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		video_id = videos{ii};
		
        metadata.(video_id).ldc_pat = sprintf('LDC2012E26/%s.mp4', video_id);
		
    end
	
    fprintf('Saving...\n');
    save(f_metadata, 'metadata');
	
end

function med13_check_data_3
	test_dir='/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/LDC2012E26';
	
	org_test_dir='/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST/LDC2012E26';
	
	error_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST/fps-error-ldc2012e26';
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test.mat');
	
	fprintf('Loading test metadata...\n');
	load(f_metadata, 'metadata');
	
	fprintf('Dir...\n');
	list = dir(test_dir);
	
	fprintf('...\n');
	count = 1;
    count2 = 1;
	
	for ii = 1:length(list),
        
        
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		file_name = list(ii).name;
		if strcmp(file_name, '.') || strcmp(file_name, '..'),
			continue;	
		end
	
		video_id = file_name(1:end-4);
		
		file_path = fullfile(test_dir, file_name);
		
		if isfield(metadata, video_id),
			fps = metadata.(video_id).fps;
			num_frames = metadata.(video_id).num_frames;
			if ~isempty(fps) && ~isempty(num_frames),
				continue;
			end
		end
		
		warning('%s Empty num_frames or fps...!!!\n', video_id);
		
		[fps, num_frames] = get_number_of_frames(file_path);
		
		if isempty(fps) || fps > 50,
			%video_file = fullfile(org_test_dir, file_name);
			%% copy original video to error dir for resizing again
			%cmd = sprintf('cp %s %s/', video_file, error_dir);
			
			error('FPS too high!!! %s\n', video_id);
			
            
            %continue;
        end
        
		if isempty(num_frames),
			error('Empty num_frames %\n', video_id);
		end
		
		fprintf('[%d] Updating for video %s ...\n', count2, video_id);
		count2 = count2 + 1;
        metadata.(video_id).fps = fps;
        metadata.(video_id).num_frames = num_frames;
        metadata.(video_id).ldc_pat = 'LDC2012E26';
		
    end
	
    fprintf('Saving...\n');
    save(f_metadata, 'metadata');
	
end

%load list of test video (ldc2012e26) and check if fps is too high.
% if it is too high then?
% --	move original videos to a folder
function med13_check_data_2
	test_dir='/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/LDC2012E26';
	
	org_test_dir='/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST/LDC2012E26';
	
	error_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST/fps-error-ldc2012e26';
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test.mat');
	
	fprintf('Dir...\n');
	list = dir(test_dir);
	
	fprintf('...\n');
	count = 1;
    metadata = struct;
    
	for ii = 1:length(list),
        
        
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		file_name = list(ii).name;
		if strcmp(file_name, '.') || strcmp(file_name, '..'),
			continue;	
		end
	
		video_id = file_name(1:end-4);
		
		file_path = fullfile(test_dir, file_name);
		
		[fps, num_frames] = get_number_of_frames(file_path);
		
		if isempty(fps) || fps > 50,
			video_file = fullfile(org_test_dir, file_name);
			%% copy original video to error dir for resizing again
			cmd = sprintf('cp %s %s/', video_file, error_dir);
			
			fprintf('%d - %s', count, video_id);
			count = count+1;
			
			system(cmd);
            
            continue;
        end
        
		
        metadata.(video_id).fps = fps;
        metadata.(video_id).num_frames = num_frames;
        metadata.(video_id).ldc_pat = 'LDC2012E26';
		
    end
	
    fprintf('Saving...\n');
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
		%log(msg);
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


function med13_check_data_1


	f_clip_lookup = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/doc/clip_location_lookup_table.csv';

	fh = fopen(f_clip_lookup, 'r');

	fprintf('Loading look up table...\n');

	c_lookup = textscan(fh, '%s %s %s %s', 'delimiter', ',');

	fclose(fh);

	clips = c_lookup{1};
	disks = c_lookup{3};
	paths = c_lookup{4};


	org_vid_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST';

	clip_ext = '.mp4';
	clip_prefix = 'HVC';

	fprintf('Checking...\n');

	videos = struct;
	f_video_lookup = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/video_lookup.mat';
	if ~exist(f_video_lookup, 'file'),
		for ii = 2:length(clips),
			if ~mod(ii, 1000),
				fprintf('%d ', ii);
			end
			
			clip = str2num(strtrim(strrep(clips{ii}, '"', '')));
			disk = strtrim(strrep(disks{ii}, '"', ''));
			path = strtrim(strrep(paths{ii}, '"', ''));
			
			clip_name = sprintf('%s%06d', clip_prefix, clip);
			clip_rel_path = fullfile(disk, path, [clip_name, '.mp4']);
			
			videos.(clip_name) = clip_rel_path;
			clip_org_path = fullfile(org_vid_dir, clip_rel_path);
			if ~exist(clip_org_path, 'file'),
				warning('File %s does not exist!\n', clip_org_path);
			end
			
		end
		
		save(f_video_lookup, 'videos');
	else
		load(f_video_lookup, 'videos');
	end
	
	fprintf('\n');
	
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';

	clip_mds = {	'EVENTS-10Ex_20130405_ClipMD.csv', ...
					'EVENTS-100Ex_20130405_ClipMD.csv', ...
					'EVENTS-130Ex_20130405_ClipMD.csv', ...
					'EVENTS-BG_20130405_ClipMD.csv', ...
					'KINDREDTEST_20130501_ClipMD.csv', ...
					'MEDTEST_20130501_ClipMD.csv', ...
					'RESEARCH_20130501_ClipMD.csv' ...
					};

	for jj = 1:length(clip_mds),
		csv_file = fullfile(csv_dir, clip_mds{jj});
		check_clipmd_file(videos, csv_file);
	end

end

function check_clipmd_file(videos, csv_file),

	fprintf('--- Checking file %s ...\n', csv_file);
	
	fh = fopen(csv_file);
	
	cvs_infos = textscan(fh, '%s %s %s %s %s', 'delimiter', ',');
	clip_ids = cvs_infos{1};
	clip_files = cvs_infos{2};
	
	fclose(fh);
		
	clip_prefix = 'HVC';
	
	for ii = 2:length(clip_ids),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		clip_id = str2num(strtrim(strrep(clip_ids{ii}, '"', '')));
		clip_file = str2num(strtrim(strrep(clip_files{ii}, '"', '')));
	
		clip_name = sprintf('%s%06d', clip_prefix, clip_id);
		
		if ~isfield(videos, clip_name),
			warning('Video %s does not exist!\n', clip_name);
		end
		
		clip_file_ = sprintf('%s%06d.mp4', clip_prefix, clip_id);
		
		if strcmp(clip_file, clip_file_),
			error('Clip file not same %s!!!\n', clip_file);
		end
	end
	
	fprintf('\n');
end
