
function calker_cal_train_kernel(proj_name, exp_name, ker)

	feature_ext = ker.feat;

	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

	kerPath = sprintf('%s/kernels/%s/%s', calker_exp_dir, ker.dev_pat, ker.devname);

	devHistPath = sprintf('%s/kernels/%s/%s.mat', calker_exp_dir, ker.dev_pat, ker.histName);
	selLabelPath = sprintf('%s/kernels/%s/%s.sel.mat', calker_exp_dir, ker.dev_pat, ker.histName);
	
	scaleParamsPath = sprintf('%s/kernels/%s/%s.mat', calker_exp_dir, ker.dev_pat, ker.scaleparamsName);
	
	log2g_list = ker.startG:ker.stepG:ker.endG;
	numLog2g = length(log2g_list);

	fprintf('\tLoading devel features for kernel %s ... \n', feature_ext) ;
	if exist(devHistPath),
		load(devHistPath);
	else
		[dev_hists, sel_feat] = calker_load_traindata(proj_name, exp_name, ker);
		
		if ker.feature_scale == 1,	
			fprintf('Feature scaling...\n');	
			[dev_hists, scale_params] = calker_feature_scale(dev_hists);	
			save(scaleParamsPath, 'scale_params');		
		end
		
		fprintf('\tSaving devel features for kernel %s ... \n', feature_ext) ;
		save(devHistPath, 'dev_hists', '-v7.3');
		save(selLabelPath, 'sel_feat');
		
	end

	if ker.cross,
		parfor jj = 1:numLog2g,
			cv_ker = ker;
			log2g = log2g_list(jj);
			gamma = 2^log2g;	
			cv_ker.mu = gamma;
			cv_kerPath = sprintf('%s.gamma%s.mat', kerPath, num2str(gamma));
			
			if ~exist(cv_kerPath),
				fprintf('\tCalculating devel kernel %s with gamma = %f... \n', feature_ext, gamma) ;	
				cv_ker = calcKernel(cv_ker, dev_hists);
				
				fprintf('\tSaving kernel ''%s''.\n', cv_kerPath) ;
				par_save( cv_kerPath, cv_ker );
			else
				fprintf('Skipped calculating kernel [%s]...\n', cv_kerPath);
			end			
		end
	else
		heu_kerPath = sprintf('%s.heuristic.mat', kerPath);
		if ~exist(heu_kerPath),
			fprintf('\tCalculating devel kernel %s with heuristic gamma ... \n', feature_ext) ;	
			ker = calcKernel(ker, dev_hists);
			
			fprintf('\tSaving kernel ''%s''.\n', heu_kerPath) ;
			par_save( heu_kerPath, ker );
		else
			fprintf('Skipped calculating kernel [%s]...\n', heu_kerPath);
		end		
	end

end

function par_save( output_file, ker )
	ssave(output_file, '-STRUCT', 'ker', '-v7.3');
end
