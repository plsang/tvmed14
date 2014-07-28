function calker_main(proj_name, exp_id, feature_ext, varargin)

addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker-v6/support');
addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');
addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox');
vl_setup;

exp_name = [proj_name, '-', exp_id];
%seg_name = ['segment-', exp_id];
seg_name = exp_id;

feat_dim = 4000;
ker_type = 'kl2';
cross = 0;
open_pool = 0;
suffix = '';
test_pat = 'kindredtest';
eventkit = 'EK10Ex';
miss_type = 'RN'; % RN: Related example as Negative, RP: Related example as Positive, NR: No related example

for k=1:2:length(varargin),

	opt = lower(varargin{k});
	arg = varargin{k+1} ;
  
	switch opt
		case 'cross'
			cross = arg;
		case 'pool' ;
			open_pool = arg ;
		case 'cv' ;
			cv = arg ;
		case 'ker' ;
			ker_type = arg ;
		case 'suffix'
			suffix = arg ;
		case 'dim'
			feat_dim = arg;
		case 'ek'
			eventkit = arg;	
		case 'miss'
			miss_type = arg;	
		case 'test'
			test_pat = arg;	
		otherwise
			error(sprintf('Option ''%s'' unknown.', opt)) ;
	end  
end

ker = calker_build_kerdb(feature_ext, ker_type, feat_dim, cross, suffix);

ker.prms.tvprefix = 'TVMED13';
ker.prms.tvtask = 'PS';
ker.prms.eventkit = eventkit; % 'EK130Ex';
ker.prms.rtype = miss_type;	% RN: Related example as Negative, RP: Related example as Positive, NR: No related example 
ker.prms.train_fea_pat = 'devel';	% train pat name where local features are stored
ker.prms.test_fea_pat = 'devel';	% train pat name where local features are stored

ker.prms.meta_file = sprintf('%s/%s/metadata/%s-%s-%s-%s/database.mat', ker.proj_dir, proj_name, ker.prms.tvprefix, ker.prms.tvtask, ker.prms.eventkit, ker.prms.rtype);
ker.prms.seg_name = seg_name;

ker.dev_pat = 'dev';
ker.test_pat = test_pat;
ker.prms.test_meta_file = sprintf('%s/%s/metadata/%s-REFTEST-%s/database.mat', ker.proj_dir, proj_name, ker.prms.tvprefix, upper(test_pat));

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
ker.log_dir = fullfile(calker_exp_dir, 'log');
 
%if ~exist(calker_exp_dir, 'file'),
mkdir(fullfile(calker_exp_dir, 'metadata'));
mkdir(fullfile(calker_exp_dir, 'kernels', ker.dev_pat));
mkdir(fullfile(calker_exp_dir, 'kernels', ker.test_pat));
mkdir(fullfile(calker_exp_dir, 'scores', ker.test_pat));
mkdir(fullfile(calker_exp_dir, 'models'));
mkdir(fullfile(calker_exp_dir, 'log'));
%end

%open pool
if matlabpool('size') == 0 && open_pool > 0, matlabpool(open_pool); end;
calker_cal_train_kernel(proj_name, exp_name, ker);
calker_train_kernel(proj_name, exp_name, ker);
calker_cal_test_kernel(proj_name, exp_name, ker);
calker_test_kernel(proj_name, exp_name, ker);
calker_cal_map(proj_name, exp_name, ker);
calker_cal_rank(proj_name, exp_name, ker);

%close pool
if matlabpool('size') > 0, matlabpool close; end;
