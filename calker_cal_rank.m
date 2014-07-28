function calker_cal_rank(proj_name, exp_name, ker)
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
	
	test_db_file = sprintf('database_%s.mat', ker.test_pat);
	
	calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);
	
	fprintf('Loading ref meta file \n');
	
	load(ker.prms.test_meta_file, 'database');
	
	if isempty(database)
		error('Empty metadata file!!\n');
	end
	
	scorePath = sprintf('%s/scores/%s/%s-%s/%s.%s.scores.mat', calker_exp_dir, ker.test_pat, ker.prms.eventkit, ker.prms.rtype, ker.name, ker.type);
	scoreDir = fileparts(scorePath);
	
	videoScorePath = sprintf('%s/scores/%s/%s.video.scores.mat', calker_exp_dir, ker.test_pat, ker.name);
	mapPath = sprintf('%s/scores/%s/%s.map.csv', calker_exp_dir, ker.test_pat, ker.name);
    
	if ~checkFile(scorePath), 
		warning('File not found!! %s \n', scorePath);
		return;
	end
	
	scores = load(scorePath);
	
	n_event = length(database.event_names);
	events = database.event_ids;
	
	fprintf('Ranking for feature %s...\n', ker.name);
	
	
	for jj = 1:n_event,
		event_name = events{jj};
		
		
		this_scores = scores.(event_name);
		
		fprintf('-- [%d] Ranking for event [%s]...\n', jj, event_name);
		
		[sorted_scores, sorted_idx] = sort(this_scores, 'descend');
		
		rankFile = sprintf('%s/%s.%s.video.rank', scoreDir, event_name, ker.name);
		
		fh = fopen(rankFile, 'w');
		for kk=1:length(sorted_scores),
			rank_idx = sorted_idx(kk);
			fprintf(fh, '%s %f\n', database.clip_names{rank_idx}, sorted_scores(kk));
		end
		
		fclose(fh);
	end	
	
end