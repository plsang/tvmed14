function calker_cal_video_scores(proj_name, exp_name, ker)
	
	calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker', proj_name, exp_name);
	scorePath = sprintf('%s/scores/%s.scores.mat', calker_exp_dir, ker.name);
	
	if ~checkFile(scorePath), 
		error('File not found!! %s \n', scorePath);
	end
	scores = load(scorePath);

	db_file = fullfile(calker_exp_dir, 'metadata', 'database_test.mat');
    load(db_file, 'database');
	
	

end