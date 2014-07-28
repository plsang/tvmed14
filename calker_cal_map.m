function calker_cal_map(proj_name, exp_name, ker, videolevel)
	
	%videolevel: 1 (default): video-based approach, 0: segment-based approach
	
	if ~exist('videolevel', 'var'),
		videolevel = 1;
	end
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
	
	calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);
	
	fprintf('Loading ref meta file \n');
	
	load(ker.prms.test_meta_file, 'database');
	
	if isempty(database)
		error('Empty metadata file!!\n');
	end
	
	% event names
	n_event = length(database.event_names);
	events = database.event_ids;
	
	fprintf('Scoring for feature %s...\n', ker.name);

	
	scorePath = sprintf('%s/scores/%s/%s-%s/%s.%s.scores.mat', calker_exp_dir, ker.test_pat, ker.prms.eventkit, ker.prms.rtype, ker.name, ker.type);
	videoScorePath = sprintf('%s/scores/%s/%s.video.scores.mat', calker_exp_dir, ker.test_pat, ker.name);
	mapPath = sprintf('%s/scores/%s/%s-%s/%s.%s.map.csv', calker_exp_dir, ker.test_pat, ker.prms.eventkit, ker.prms.rtype, ker.name, ker.type);
    
	if ~checkFile(scorePath), 
		error('File not found!! %s \n', scorePath);
	end
	scores = load(scorePath);
			
	m_ap = zeros(1, n_event);

	if videolevel | (~videolevel & exist(videoScorePath, 'file')),	% video-based
	
		if ~videolevel,
			fprintf('Loading video scores path...\n');
			scores = load(videoScorePath);
		end
	
		
		for jj = 1:n_event,
			event_name = events{jj};
			this_scores = scores.(event_name);
			
			fprintf('Scoring for event [%s]...\n', event_name);
			
			[~, idx] = sort(this_scores, 'descend');
			%gt_idx = find(database.label == jj);
			gt_idx = find(ismember(database.clip_names, database.ref.(event_name)));
			
			rank_idx = arrayfun(@(x)find(idx == x), gt_idx);
			
			sorted_idx = sort(rank_idx);	
			ap = 0;
			for kk = 1:length(sorted_idx), 
				ap = ap + kk/sorted_idx(kk);
			end
			ap = ap/length(sorted_idx);
			m_ap(jj) = ap;
			%map.(event_name) = ap;
		end	
	else 		% segment-based
		
		%% note: April 22, haven't updated for segment-based approach yet
		fprintf('Calculating scores at video level...\n');
		
		video_scores_ = cell(n_event, 1);
		
		for jj = 1:n_event,
			event_name = events{jj};
			this_scores = scores.(event_name);
			
			% choose max score of each segment as score of a video	
			fprintf('Combining scores at video level for event [%s]...\n', event_name);
			%% this_video_scores = arrayfun(@(x)max(this_scores(find(x == database.video))), unique(database.video));
			%% video_scores_{jj} = this_video_scores;
			
			% Update Sep, 10th :-), using loop instead of arrayfun
			video_ids = unique(database.video);
			this_video_scores = zeros(1, length(video_ids));
			for kk = 1:length(video_ids),
				if ~mod(kk, 1000),
					fprintf('%d ', kk);
				end
				
				%this_video_scores(kk) = max(this_scores(find(kk == database.video)));
				this_video_scores(kk) = max(this_scores(find(video_ids(kk) == database.video)));
				
			end
			fprintf('\n ');
			video_scores_{jj} = this_video_scores;
			
			fprintf('Scoring for event [%s]...\n', event_name);
			
			[~, idx] = sort(this_video_scores, 'descend');
			gt_idx = find(database.label == jj);
			
			video_idx = unique(database.video(gt_idx));
			
			rank_idx = arrayfun(@(x)find(idx == x), video_idx);
			
			sorted_idx = sort(rank_idx);	
			ap = 0;
			for kk = 1:length(sorted_idx), 
				ap = ap + kk/sorted_idx(kk);
			end
			ap = ap/length(sorted_idx);
			m_ap(jj) = ap;
			%map.(event_name) = ap;
		end	
		
		video_scores = struct;
		for jj = 1:n_event,
			event_name = events{jj};
			video_scores.(event_name) = video_scores_{jj};
		end
		
		ssave(videoScorePath, '-STRUCT', 'video_scores') ;
	end

	m_ap
	mean(m_ap)	
	%save(mapPath, 'map');
	
	fh = fopen(mapPath, 'w');
	for jj = 1:n_event,	
		event_name = events{jj};
		fprintf(fh, '%s\t%f\n', event_name, m_ap(jj));
	end
	fprintf(fh, '%s\t%f\n', 'all', mean(m_ap));
	fclose(fh);
end