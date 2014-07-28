function calker_val_kernel(proj_name, exp_name, ker, events)

    % loading labels
    calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

	calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);

	scorePath = sprintf('%s/scores/%s/%s.scores.mat', calker_exp_dir, ker.test_pat, ker.name);
	
	scorePath
	
	if exist(scorePath, 'file'), 
		fprintf('Skipped validating %s \n', scorePath);
		return;
	end
	
	models = struct;
	scores = struct;
	
	kerPath = sprintf('%s/kernels/%s/%s.heuristic.mat', calker_exp_dir, ker.dev_pat, ker.devname);	
	fprintf('Loading val kernel %s ...\n', kerPath); 
	kernels_ = load(kerPath) ;
	base = kernels_.matrix;
	
	[N, Nt] = size(base) ;
		
		
	for jj = 1:n_event,
		event_name = events{jj};
		
		modelPath = sprintf('%s/models/%s.%s.%s.model.mat', calker_exp_dir, event_name, ker.name, ker.type);
        
		if ~checkFile(modelPath),
			error('Model not found %s \n', modelPath);			
		end
		
		fprintf('Loading model ''%s''...\n', event_name);
		models.(event_name) = load(modelPath);
		
		% load train kernel
		%kerPath = sprintf('%s/kernels/%s/%s.%s.mat', calker_exp_dir, ker.test_pat, part_name, ker.type);
		
		[y, acc, dec] = svmpredict(zeros(Nt, 1), [(1:Nt)' base'], models.(event_name).libsvm_cl, '-b 1') ;	
		
		scores.(event_name) = dec(:, 1)';
	end

		
	%saving scores
	fprintf('\tSaving scores ''%s''.\n', scorePath) ;
	ssave(scorePath, '-STRUCT', 'scores') ;
	
	%fprintf('\tCalculating maps ''%s''.\n', scorePath) ;
	%calker_cal_map(proj_name, exp_name, ker, events);
end