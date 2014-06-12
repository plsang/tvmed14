function mfcc_main(proj_name, kf_name, algo)

	set_env;
	if matlabpool('size') < 1,
		matlabpool open;
	end	
	mfcc_select_features(proj_name, algo);
	matlabpool close;
	
	mfcc_do_clustering(proj_name, algo);

	if matlabpool('size') < 1,
		matlabpool open;
	end		
	
	mfcc_encode_home(proj_name, kf_name, 'devel', algo);
	mfcc_encode_home(proj_name, kf_name, 'test', algo);
	matlabpool close;

end