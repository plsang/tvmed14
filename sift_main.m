function sift_main(proj_name, kf_name, sz_pat, sift_algo, param, codebook_size, spm, start_seg, end_seg)

%% set environment variables
set_env;

%% default params
if nargin < 6,
	codebook_size = 4000;
	spm = 0;
	start_seg = 1;
	end_seg = +inf;
end

if matlabpool('size') < 1,
	matlabpool open;
end	
sift_select_features(proj_name, sift_algo, param); 
matlabpool close; 

sift_do_clustering(proj_name, sift_algo, param, codebook_size); 

if matlabpool('size') < 1,
	matlabpool open;
end	
sift_encode_home( proj_name, kf_name, sz_pat, codebook_size, spm, sift_algo, param, start_seg, end_seg );
matlabpool close; 

end