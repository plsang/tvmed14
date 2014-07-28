function calker_train_kernel(proj_name, exp_name, ker)

    test_on_train = 0;
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

	fprintf('Loading meta file \n');
	
	database = load(ker.prms.meta_file, 'database');
	database = database.database;
	
	if isempty(database)
		error('Empty metadata file!!\n');
	end
	
	selLabelPath = sprintf('%s/kernels/%s/%s.sel.mat', calker_exp_dir, ker.dev_pat, ker.histName);	
	if ~exist(selLabelPath, 'file')
		error('File not found!!\n');
	end
	
	sel_feat_ = load(selLabelPath, 'sel_feat');
	
	sel_feat = database.sel_idx & sel_feat_.sel_feat;

    kerPath = sprintf('%s/kernels/%s/%s', calker_exp_dir, ker.dev_pat, ker.devname);
	
	parfor kk = 1:length(database.event_names),
		event_name = database.event_ids{kk};
	
        modelPath = sprintf('%s/models/%s-%s/%s.%s.%s.model.mat', calker_exp_dir, ker.prms.eventkit, ker.prms.rtype, event_name, ker.name, ker.type);
		
		if checkFile(modelPath),
			fprintf('Skipped training %s \n', modelPath);
			continue;
		end
		
		fprintf('Training event ''%s''...\n', event_name);	
		
		labels = double(database.train_labels(kk, :)); % labels are row vectors
		
		%% removing 0 entry (not used for training);
		non_zero_label_idx = labels ~= 0;
		train_idx = sel_feat & non_zero_label_idx;
		labels = labels(train_idx);
		
		
		posWeight = ceil(length(find(labels == -1))/length(find(labels == 1)));
		
		log2g_list = ker.startG:ker.stepG:ker.endG;
		numLog2g = length(log2g_list);
		
		if ker.cross,
			svm = cell(numLog2g, 1);
			maxacc = cell(numLog2g, 1);
			
			for jj = 1:numLog2g,
				cv_ker = ker;
				log2g = log2g_list(jj);
				gamma = 2^log2g;	
				
				cv_kerPath = sprintf('%s.gamma%s.mat', kerPath, num2str(gamma));
				fprintf('Loading kernel %s ...\n', cv_kerPath); 
				kernels_ = load(cv_kerPath) ;
				base = kernels_.matrix(train_idx, train_idx);

				fprintf('SVM learning with predefined kernel matrix...\n');
				[svm_, maxacc_] = calker_svmkernellearn(base, labels,   ...
								   'type', 'C',        ...
								   ...%'C', 10,            ...
								   'verbosity', 0,     ...
								   ...%'rbf', 1,           ...
								   'crossvalidation', 5, ...
								   'weights', [+1 posWeight ; -1 1]') ;
				fprintf(' cur acc = %f, at gamma = %f...\n', maxacc_, gamma);
				
				svm{jj} = svm_;
				maxacc{jj} = maxacc_;
				
			end
			
			maxacc = cat(1, maxacc{:});
			[~, max_idx] = 	max(maxacc);
			svm = svm{max_idx};
			gamma = 2^log2g_list(max_idx);
			fprintf(' best acc = %f, at gamma = %f...\n', maxacc(max_idx), gamma);
			
		else
			heu_kerPath = sprintf('%s.heuristic.mat', kerPath);
			fprintf('Loading kernel %s ...\n', heu_kerPath); 
			kernels_ = load(heu_kerPath) ;
			base = kernels_.matrix(train_idx, train_idx);	% selected features
			
			fprintf('SVM learning with predefined kernel matrix...\n');
		
			svm = calker_svmkernellearn(base, labels,   ...
							   'type', 'C',        ...
							   ...%'C', 10,            ...
							   'verbosity', 0,     ...
							   ...%'rbf', 1,           ...
							   'crossvalidation', 5, ...
							   'weights', [+1 posWeight ; -1 1]') ;
							   
			if isfield(kernels_, 'mu'),
				gamma = kernels_.mu;
			end
			%clear kernels_;
		end
		

		svm = svmflip(svm, labels);
		
		svm.train_idx = train_idx;

		if strcmp(ker.type, 'echi2'),
			svm.gamma = gamma;
		end
		
		% test it on train
		if test_on_train,		
			if ker.cross,		
				cv_kerPath = sprintf('%s.gamma%s.mat', kerPath, num2str(gamma));
			else
				cv_kerPath = sprintf('%s.heuristic.mat', kerPath);
			end
			
			fprintf('Loading kernel %s ...\n', cv_kerPath); 
			kernels_ = load(cv_kerPath) ;
			base = kernels_.matrix(train_idx, train_idx);	% selected features
			
			scores = svm.alphay' * base(svm.svind, :) + svm.b ;
			errs = scores .* labels < 0 ;
			err  = mean(errs) ;
			selPos = find(labels > 0) ;
			selNeg = find(labels < 0) ;
			werr = sum(errs(selPos)) * posWeight + sum(errs(selNeg)) ;
			werr = werr / (length(selPos) * posWeight + length(selNeg)) ;
			fprintf('\tSVM training error: %.2f%% (weighed: %.2f%%).\n', ...
			  err*100, werr*100) ;
			  
			% save model
			fprintf('\tNumber of support vectors: %d\n', length(svm.svind)) ;
			%clear kernels_;
		end
		
		fprintf('\tSaving model ''%s''.\n', modelPath) ;
		par_save( modelPath, svm );	

	end
	
end

function par_save( modelPath, svm )
	ssave(modelPath, '-STRUCT', 'svm') ;
end
