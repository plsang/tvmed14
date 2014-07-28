
function hists = calker_load_testdata(proj_name, exp_name, ker)

%%Update change parameter to ker
% load database
calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);

fprintf('Loading meta file \n');
load(ker.prms.meta_file, 'database');

if isempty(database)
    error('Empty metadata file!!\n');
end

hists = zeros(ker.num_dim, size(database.clip_names, 2));

parfor ii = 1:length(database.path), %
    
	clip_name = database.clip_names{ii};
	
	segment_path = sprintf('%s/%s/feature/%s/%s/%s/%s.mat',...
					ker.proj_dir, proj_name, ker.prms.seg_name, ker.feat_raw, fileparts(ker.prms.metadata.(clip_name).ldc_pat), clip_name); 
					
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
	
	hists(:, ii) = code;
end

end


