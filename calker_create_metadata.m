function calker_create_metadata
	root_meta_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	
	output_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	
	if ~exist(output_file, 'file'),
		MEDMD = calker_load_metadata (root_meta_dir);
		save(output_file, 'MEDMD');
	end
	
	
	
	%filenames = fieldnames(MEDMD);
	
	%for ii=1:length(filenames),
	%	filename = filenames{ii};
	%	filepath = fullfile(output_dir, filename);
	%	value = MEDMD.(filename);
	%	save(filepath, 'value');
	%end
	
end

function MEDMD = calker_load_metadata(root_meta_dir)
	
	EventKit = struct;			 
	EventKit.('EK0Ex') = {'EVENTS-0Ex_20130913_ClipMD.csv', 'EVENTS-0Ex_20130913_EventDB.csv', 'EVENTS-0Ex_20130913_JudgementMD.csv'};
	EventKit.('EK10Ex') = {'EVENTS-10Ex_20130913_ClipMD.csv', 'EVENTS-10Ex_20130913_EventDB.csv', 'EVENTS-10Ex_20130913_JudgementMD.csv'};
	EventKit.('EK100Ex') = {'EVENTS-100Ex_20130913_ClipMD.csv', 'EVENTS-100Ex_20130913_EventDB.csv', 'EVENTS-100Ex_20130913_JudgementMD.csv'};
	EventKit.('EK130Ex') = {'EVENTS-130Ex_20130405_ClipMD.csv', 'EVENTS-130Ex_20130405_EventDB.csv', 'EVENTS-130Ex_20130405_JudgementMD.csv'};
	EventKit.('RESEARCH') = {'RESEARCH_20130501_ClipMD.csv', 'RESEARCH_20130501_EventDB.csv', 'RESEARCH_20130501_JudgementMD.csv'};
	
	EventBG = struct;
	EventBG.('default') = {'EVENTS-BG_20130405_ClipMD.csv', 'EVENTS-BG_20130405_EventDB.csv', 'EVENTS-BG_20130405_JudgementMD.csv'}; 
	
	RefTest = struct;
	%RefTest.('KINDREDTEST') = {'KINDREDTEST_20130501_ClipMD.csv', 'KINDREDTEST_20130501_EventDB.csv', 'KINDREDTEST_20130501_Ref.csv', 'KINDREDTEST_20130501_TrialIndex.csv'};
	%RefTest.('MEDTEST') = {'MEDTEST_20130501_ClipMD.csv', 'MEDTEST_20130501_EventDB.csv', 'MEDTEST_20130501_Ref.csv', 'MEDTEST_20130501_TrialIndex.csv'};
	RefTest.('KINDREDTEST') = {'KINDREDTEST_20130501_ClipMD.csv', 'KINDREDTEST_20130501_EventDB.csv', 'KINDREDTEST_20130501_Ref.csv'};
	RefTest.('MEDTEST') = {'MEDTEST_20130501_ClipMD.csv', 'MEDTEST_20130501_EventDB.csv', 'MEDTEST_20130501_Ref.csv'};
	
	UnrefTest = struct;
	%UnrefTest.('PROGAll_PS') = {'PROGAll_PS_20130702_ClipMD.csv', 'PROGAll_PS_20130702_EventDB.csv', 'PROGAll_PS_20130702_TrialIndex.csv'};
	%UnrefTest.('PROGSub_PS') = {'PROGSub_PS_20130702_ClipMD.csv', 'PROGSub_PS_20130702_EventDB.csv', 'PROGSub_PS_20130702_TrialIndex.csv'};
	%UnrefTest.('PROGALL_AH') = {'PROGAll_AH_20130913_ClipMD.csv', 'PROGAll_AH_20130913_EventDB.csv', 'PROGAll_AH_20130913_TrialIndex.csv'};
	%UnrefTest.('PROGSub_AH') = {'PROGSub_AH_20130913_ClipMD.csv', 'PROGSub_AH_20130913_EventDB.csv', 'PROGSub_AH_20130913_TrialIndex.csv'};
	UnrefTest.('PROGAll_PS') = {'PROGAll_PS_20130702_ClipMD.csv', 'PROGAll_PS_20130702_EventDB.csv'};
	UnrefTest.('PROGSub_PS') = {'PROGSub_PS_20130702_ClipMD.csv', 'PROGSub_PS_20130702_EventDB.csv'};
	UnrefTest.('PROGALL_AH') = {'PROGAll_AH_20130913_ClipMD.csv', 'PROGAll_AH_20130913_EventDB.csv'};
	UnrefTest.('PROGSub_AH') = {'PROGSub_AH_20130913_ClipMD.csv', 'PROGSub_AH_20130913_EventDB.csv'};
	
	MEDDB = struct;
	MEDDB.EventKit = EventKit;
	MEDDB.EventBG = EventBG;
	MEDDB.RefTest = RefTest;
	MEDDB.UnrefTest = UnrefTest;
	
	MEDMD = struct;
	
	types = fieldnames(MEDDB);
	for ii=1:length(types),
		type = types{ii};
		subtypes = fieldnames(MEDDB.(type));
		
		for jj=1:length(subtypes),
			subtype = subtypes{jj};
			files = MEDDB.(type).(subtype);
			for kk = 1:length(files),
				file = files{kk};
				filepath = fullfile(root_meta_dir, file);
				
				[~, filename] = fileparts(file);
				splits = regexp(filename, '_', 'split');
				metatype = splits{length(splits)};
				
				switch metatype,
					case 'ClipMD'
						[clips, durations] = load_clip_md_(filepath);
						MEDMD.(type).(subtype).clips = clips;
						MEDMD.(type).(subtype).durations = durations;
					case 'EventDB'
						[eventids, eventnames] = load_event_db_(filepath);
						MEDMD.(type).(subtype).eventids = eventids;
						MEDMD.(type).(subtype).eventnames = eventnames;
					case 'Ref'
						events = load_ref_(filepath);
						MEDMD.(type).(subtype).ref = events;
					case 'JudgementMD'
						events = load_judgement_md_(filepath);
						MEDMD.(type).(subtype).judge = events;
					case 'TrialIndex'
						[trialids, clipids, eventids] = load_trial_index_(filepath);
						MEDMD.(type).(subtype).trialids = trialids;
					otherwise
						disp('Unknown metatype %s \n', metatype);
				end
				
			end
		end
	end
					
end

function infos = parse_raw_csv_infos_(csv_infos)
	%fprintf('--- Parsing raw csv file ...\n');
	
	infos = struct;
	
	for ii = 1:length(csv_infos),
		field = strtrim(strrep(csv_infos{ii}{1}, '"', ''));
		
		% trim '"' in all elements
		% Non-scalar in output --> Set 'UniformOutput' to false.
		values = cellfun(@(x) strtrim(strrep(x, '"', '')), csv_infos{ii}(2:end), 'UniformOutput', false );

		infos.(field) = values;
	end
	
end


function [clips, durations] = load_clip_md_(path)
	fprintf('--- Loading clip metadata from file %s ...\n', path);
	
	fh = fopen(path);
	
	csv_infos = textscan(fh, '%s %s %s %s %s', 'delimiter', ',');
	fclose(fh);
	
	infos_ = parse_raw_csv_infos_(csv_infos);
	
	clip_prefix = 'HVC';
	
	clips = {};
	durations = [];
	
	for ii = 1:length(infos_.ClipID),
		clip_id = infos_.ClipID{ii};
		clip_name = sprintf('%s%s', clip_prefix, clip_id);
		clips{end+1} = clip_name;
		durations(end+1) = str2num(infos_.DURATION{ii});
	end
	
end

function [eventids, eventnames] = load_event_db_(path)
	fprintf('--- Loading event metadata from file %s ...\n', path);
	
	fh = fopen(path);
	csv_infos = textscan(fh, '%s %s', 'delimiter', ',');
	fclose(fh);
	
	infos_ = parse_raw_csv_infos_(csv_infos);
	
	
	eventids = {};
	eventnames = {};
	
	for ii = 1:length(infos_.EventID),	
		if regexp(infos_.EventID{ii}, 'E\d+'),
			eventids{end+1} = infos_.EventID{ii};
			eventnames{end+1} = infos_.EventName{ii};
		end
	end
	
end

function [trialids, clipids, eventids] = load_trial_index_(path)
	fprintf('--- Loading trial index metadata from file %s ...\n', path);
	
	fh = fopen(path);
	csv_infos = textscan(fh, '%s %s %s', 'delimiter', ',');
	fclose(fh);
	
	infos_ = parse_raw_csv_infos_(csv_infos);
	
	trialids = infos_.TrialID;
	clipids = infos_.ClipID;
	eventids = infos_.EventID;

end

%%% events is a struct contains all true positive clips
function events = load_ref_(path)
	fprintf('--- Loading reference metadata from file %s ...\n', path);
	
	fh = fopen(path);
	csv_infos = textscan(fh, '%s %s', 'delimiter', ',');
	fclose(fh);
	
	infos_ = parse_raw_csv_infos_(csv_infos);
	
	% building events structure
	hit_idx = find(ismember(infos_.Targ, 'y'));
	hit_trials = infos_.TrialID(hit_idx);
	
	events = struct;
	for ii = 1:length(hit_trials),
	
		splits = regexp(hit_trials{ii}, '\.', 'split');
		if length(splits) ~= 2,
			error('Unknown format id...\n');
		end
		
		clip_id = splits{1};
		clip_name = sprintf('HVC%s', clip_id);
		event = splits{2};
		if ~isfield(events, event),
			events.(event){1} = clip_name;
		else
			events.(event){end+1} = clip_name;
		end	
		
	end
	
end

%% events.E0XX.positive: list positive videos
%% events.E0XX.miss: list miss videos

function events = load_judgement_md_(path)
	
	fprintf('--- Loading judgement metadata from file %s ...\n', path);
	
	fh = fopen(path);
	csv_infos = textscan(fh, '%s %s %s', 'delimiter', ',');
	fclose(fh);
	
	infos_ = parse_raw_csv_infos_(csv_infos);
	
	events = struct;
	
	%% positive instance
	hit_idx = find(ismember(infos_.INSTANCE_TYPE, 'positive'));
	hit_clipids = infos_.ClipID(hit_idx);
	hit_eventids = infos_.EventID(hit_idx);
	
	for ii = 1:length(hit_clipids),
		clip_id = hit_clipids{ii};
		clip_name = sprintf('HVC%s', clip_id);
		event = hit_eventids{ii};
		if ~isfield(events, event),
			events.(event).positive{1} = clip_name;
		else
			events.(event).positive{end+1} = clip_name;
		end	
	end
	
	%% miss instance
	hit_idx = find(ismember(infos_.INSTANCE_TYPE, 'miss'));
	hit_clipids = infos_.ClipID(hit_idx);
	hit_eventids = infos_.EventID(hit_idx);
	
	for ii = 1:length(hit_clipids),
		clip_id = hit_clipids{ii};
		clip_name = sprintf('HVC%s', clip_id);
		event = hit_eventids{ii};
		if ~isfield(events, event) || ~isfield(events.(event), 'miss'),
			events.(event).miss{1} = clip_name;
		else
			events.(event).miss{end+1} = clip_name;
		end	
	end
	
end