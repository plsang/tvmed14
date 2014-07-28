function calker_cal_test_kernel(proj_name, exp_name, ker)
	
feature_ext = ker.feat;

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);

fprintf('Loading test meta file \n');
database = load(ker.prms.test_meta_file, 'database');
database = database.database;

devHistPath = sprintf('%s/kernels/%s/%s.mat', calker_exp_dir, ker.dev_pat, ker.histName);
if ~exist(devHistPath),
	error('File [%s] not found!\n');
end
dev_hists = load(devHistPath, 'dev_hists');
dev_hists = dev_hists.dev_hists;

scaleParamsPath = sprintf('%s/kernels/%s/%s.mat', calker_exp_dir, ker.dev_pat, ker.scaleparamsName);

fprintf('\tLoading kernel info for heuristic mu... \n') ;
heu_kerPath = sprintf('%s/kernels/%s/%s.heuristic.mat', calker_exp_dir, ker.dev_pat, ker.devname);
heu_ker = load( heu_kerPath );

if strcmp(ker.type, 'echi2'),
	if ~isfield(heu_ker, 'mu'),
		error('Mu is not set in kernel info...\n');
	end
	ker.mu = heu_ker.mu;	
end

f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
fprintf('Loading metadata...\n');
metadata_ = load(f_metadata, 'metadata');
metadata = metadata_.metadata;
prms.metadata = metadata;

num_part = ceil(size(database.clip_names, 2)/ker.chunk_size);
cols = fix(linspace(1, size(database.clip_names, 2) + 1, num_part+1));

% cal test kernel using num_part partition

fprintf('-- Calculating test kernel %s with %d partition(s) \n', feature_ext, num_part);

parfor jj = 1:num_part,
	sel = [cols(jj):cols(jj+1)-1];
	part_name = sprintf('%s_%d_%d', ker.testname, cols(jj), cols(jj+1)-1);
	kerPath = sprintf('%s/kernels/%s/%s.%s.mat', calker_exp_dir, ker.test_pat, part_name, ker.type);

	if ~exist(kerPath, 'file'),
		
		% Update Sep 6, 2013: load test hist here
		
		part_length = cols(jj+1) - cols(jj);
		test_hists = zeros(ker.num_dim, part_length);
		
		fprintf('----[%d/%d] Loading test data [feature: %s] [ker_type = %s] [range: %d-%d]... \n', jj, num_part, feature_ext, ker.type, cols(jj), cols(jj+1)-1);
		
		for ii = 1:part_length, %
		
			clip_name = database.clip_names{ii + cols(jj) - 1};
			
			%segment_path = sprintf('%s/%s/feature/%s/%s/%s/%s/%s.mat',...
			%	ker.proj_dir, proj_name, ker.prms.seg_name, ker.feat_raw, ker.prms.test_fea_pat, clip_name, clip_name);   

			segment_path = sprintf('%s/%s/feature/%s/%s/%s/%s.mat',...
					ker.proj_dir, proj_name, ker.prms.seg_name, ker.feat_raw, fileparts(prms.metadata.(clip_name).ldc_pat), clip_name); 
					
			%segment_path = database_path{ii + cols(jj) - 1};
			
			if ~exist(segment_path),
				warning('File [%s] does not exist! Generating random feature... !!\n', segment_path);
				%code = ones(ker.num_dim, 1);
				code = zeros(ker.num_dim, 1);
			else
				code = load(segment_path, 'code');
				code = code.code;
				
				if size(code, 1) ~= ker.num_dim,
					warning('Dimension mismatch [%d-%d-%s]. Generating random feature... !!\n', size(code, 1), ker.num_dim, segment_path);
					%code = ones(ker.num_dim, 1);
					code = zeros(ker.num_dim, 1);			
				elseif any(isnan(code)),
					warning('Feature contains NaN [%s] !!\n', segment_path);
					%code(isnan(code)) = 0;
					code = zeros(ker.num_dim, 1);
				elseif all(code == 0),
					warning('All zeros feature [%s] !!\n', segment_path);	
					%code = ones(ker.num_dim, 1);
				end
			end
			
			if ~all(code == 0),
				if strcmp(ker.feat_norm, 'l2'),
					code = code / norm(code, 2);
				elseif strcmp(ker.feat_norm, 'l1'),
					code = code / norm(code, 1);
				else
					error('unknown norm!\n');
				end
			end
			
			test_hists(:, ii) = code;
		end

		if ker.feature_scale == 1,	
			fprintf('---- Feature scaling...\n');	
			if ~exist(scaleParamsPath, 'file'),
				error('Scale parameters [%s] not found!\n', scaleParamsPath);
			end
			scale_params = load(scaleParamsPath, 'scale_params');	
			test_hists = calker_feature_scale(test_hists, scale_params.scale_params);	
		end
		
		fprintf('---- [%d/%d] Calculating test kernel [feature: %s] [ker_type = %s] [range: %d-%d]... \n', jj, num_part, feature_ext, ker.type, cols(jj), cols(jj+1)-1);
		
		testKer = calcKernel(ker, dev_hists, test_hists);
		%save test kernel
		fprintf('---- Saving kernel ''%s''.\n', kerPath) ;
		par_save( kerPath, testKer ) ;
			
	else	
		fprintf('Skipped calculating test kernel %s [range: %d-%d] \n', feature_ext, cols(jj), cols(jj+1)-1);
	end

end


%% clean up
clear dev_hists;
clear test_hists;
clear kernel;
clear testKer;
end


function par_save( kerPath, testKer )
	ssave(kerPath, '-STRUCT', 'testKer', '-v7.3') ;
end
