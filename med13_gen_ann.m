
function med13_gen_ann ()
	fprintf('Generating devel annotation...\n');
	med13_gen_dev_ann ('EK10');
	med13_gen_dev_ann ('EK100');
	%med13_gen_dev_ann ('EK130');
	%med13_gen_val_ann ('medtest');
	%med13_gen_val_ann ('kindredtest');
	
	
	%med13_gen_video_lst();
	
	
	
end

function med13_gen_video_lst()

	fprintf('Gen dev videos...\n');
	common_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common';
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	%% dev	
	eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	f_eventvideo_csv = 'EVENTS-130Ex_20130405_ClipMD.csv';

	f_eventvideo_csv = fullfile(csv_dir,f_eventvideo_csv);	
	f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	
	list_eventvideo = load_video_list(f_eventvideo_csv);
	list_bgvideo = load_video_list(f_eventbg_csv);
	
	list_video = [list_eventvideo, list_bgvideo];
	
	f_dev = sprintf('%s/trecvidmed13.dev.lst', common_dir);
	
	fh = fopen(f_dev, 'w');
	
	for ii=1:length(list_video),
		video_id = list_video{ii};		
		fprintf(fh, '%s\n', video_id);	
	end
	
	fclose(fh);	
	%% medtest
	fprintf('Gen medtest videos...\n');
	csv_file = 'MEDTEST_20130501_ClipMD.csv';
	f_csv = fullfile(csv_dir, csv_file);	
	list_video = load_video_list(f_csv);

	f_list = sprintf('%s/trecvidmed13.medtest.lst', common_dir);
	
	fh = fopen(f_list, 'w');
	for ii=1:length(list_video),
		video_id = list_video{ii};		
		fprintf(fh, '%s\n', video_id);	
	end
	fclose(fh);	
	
	%% kindredtest
	fprintf('Gen kindredtest videos...\n');
	csv_file = 'KINDREDTEST_20130501_ClipMD.csv';
	f_csv = fullfile(csv_dir, csv_file);	
	list_video = load_video_list(f_csv);

	f_list = sprintf('%s/trecvidmed13.kindredtest.lst', common_dir);
	
	fh = fopen(f_list, 'w');
	for ii=1:length(list_video),
		video_id = list_video{ii};		
		fprintf(fh, '%s\n', video_id);	
	end
	fclose(fh);	
end

function med13_gen_val_ann (set)
	% set = 'medtest', 'kindredtest';
	csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	
	if strcmp(set, 'kindredtest'),
		csv_name = 'KINDREDTEST_20130501_Ref.csv';
	elseif strcmp(set, 'medtest'),
		csv_name = 'MEDTEST_20130501_Ref.csv';
	else
		error(' Unknow test set\n');
	end
	
	csv_file = fullfile(csv_dir, csv_name);
	
	fh = fopen(csv_file, 'r');
	cvs_infos = textscan(fh, '%s %s', 'delimiter', ',');
	trials = cvs_infos{1};
	targets = cvs_infos{2};
	
	hit_idx = find(ismember(targets, '"y"'));
	size(hit_idx)
	hit_trials = trials(hit_idx);
	
	events = struct;
	for ii = 1:length(hit_trials),
		trial = strtrim(strrep(hit_trials{ii}, '"', ''));
		
		splits = regexp(trial, '\.', 'split');
		if length(splits) ~= 2,
			error('Unknown format id...\n');
		end
		vid_num = splits{1};
		video_id = sprintf('HVC%s', vid_num);
		event = splits{2};
		if ~isfield(events, event),
			events.(event){1} = video_id;
		else
			events.(event){end+1} = video_id;
		end	
	end
	
	fclose(fh);
	
	%% writing event list to file...
	meta_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/val';
	out_dir = sprintf('%s/%s', meta_dir, set);
	
	if ~exist(out_dir, 'file'),
		mkdir(out_dir);
	end
	
	event_list = fieldnames(events);
	
	for ii=1:length(event_list),
		event_name = event_list{ii};
		
		fprintf('-- Gen metadata for event %s ...\n', event_name);
		event_file = sprintf('%s/%s.%s.lst', out_dir, event_name, set);
		fh = fopen(event_file, 'w');	
		
		pos_list = events.(event_name);
		% positive events
		for jj=1:length(pos_list),
		
			file_name = pos_list{jj};
			
			fprintf(fh, '%s\n', file_name);
		end
	end
	
end

function med13_gen_dev_ann (set)
	% set: Ex10, Ex100, Ex130
	% list of event videos
	meta_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/dev';
	out_dir = sprintf('%s/%s', meta_dir, set);
	
	event_list_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/data/events';
	
	if ~exist(out_dir, 'file'),
		mkdir(out_dir);
	end
	
	% gen event num
	events = {};
	for ii=1:40,
		events{ii} = sprintf('E%03d', ii);
	end
	
	% 
	fprintf('Gen metadata for set %s...\n', set);

	for ii=1:length(events),
		event_name = events{ii};
		event_set_dir = sprintf('%s/%s-%s', event_list_dir, event_name, set);
		
		%if ii > 30 && strcmp(set, 'EK130'),
		%	event_set_dir = sprintf('%s/%s-%s', event_list_dir, event_name, 'EK100');
		%end
		
		fprintf('-- Gen metadata for event %s ...\n', event_name);
		event_file = sprintf('%s/%s.%s.lst', out_dir, event_name, set);
		fh = fopen(event_file, 'w');	
		
		% positive events
		pos_event_dir = sprintf('%s/positive', event_set_dir);
		pos_list = dir(pos_event_dir);
		for jj=1:length(pos_list),
			file_name = pos_list(jj).name;
			if strcmp(file_name, '.') || strcmp(file_name, '..'),
				continue;	
			end
			fprintf(fh, '%s >.< %s\n', file_name(1:end-4), 'positive');
		end
		
		% miss events
		miss_event_dir = sprintf('%s/miss', event_set_dir);
		miss_list = dir(miss_event_dir);
		for jj=1:length(miss_list),
			file_name = miss_list(jj).name;
			if strcmp(file_name, '.') || strcmp(file_name, '..'),
				continue;	
			end
			fprintf(fh, '%s >.< %s\n', file_name(1:end-4), 'miss');
		end

		fclose(fh);
	end
end

function videos = med13_get_event_video_list (set)
	% set: Ex10, Ex100, Ex130
	% list of event videos
	meta_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/events/devel';
	out_dir = sprintf('%s/%s', meta_dir, set);
	
	event_list_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/data/events';
	
	if ~exist(out_dir, 'file'),
		mkdir(out_dir);
	end
	
	% gen event num
	events = {};
	for ii=6:15,
		events{end+1} = sprintf('E%03d', ii);
	end
	
	for ii=21:30,
		events{end+1} = sprintf('E%03d', ii);
	end
	
	% 
	fprintf('Gen metadata for set %s...\n', set);

	videos = {};
	
	for ii=1:length(events),
		event_name = events{ii};
		event_set_dir = sprintf('%s/%s-%s', event_list_dir, event_name, set);
		
		fprintf('-- Gen metadata for event %s ...\n', event_name);
		
		
		
		% positive events
		pos_event_dir = sprintf('%s/positive', event_set_dir);
		pos_list = dir(pos_event_dir);
		for jj=1:length(pos_list),
			file_name = pos_list(jj).name;
			if strcmp(file_name, '.') || strcmp(file_name, '..'),
				continue;	
			end
			videos{end+1} = file_name(1:end-4);	
		end
		
		% miss events
		miss_event_dir = sprintf('%s/miss', event_set_dir);
		miss_list = dir(miss_event_dir);
		for jj=1:length(miss_list),
			file_name = miss_list(jj).name;
			if strcmp(file_name, '.') || strcmp(file_name, '..'),
				continue;	
			end
			videos{end+1} = file_name(1:end-4);	
		end

		
	end
end