
function calker_cal_kernel(proj_name, exp_name, ker)



feature_ext = ker.feat;

calker_exp_dir = sprintf('/net/per900a/raid0/plsang/%s/experiments/%s-calker/%s', proj_name, exp_name, ker.feat);

kerPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.devname);
kerDescrPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.descname);
devHistPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.histName);

if ~checkFile(kerPath)
    %% kernel on train-train pat
    fprintf('\tLoading devel features for kernel %s ... \n', feature_ext) ;

    if exist(devHistPath),
        load(devHistPath);
    else
        dev_hists = calker_load_traindata(proj_name, exp_name, ker);
        save(devHistPath, 'dev_hists', '-v7.3');
    end

    %fprintf('Scaling data before cal kernel...\n');
    %dev_hists = scaledata(dev_hists, 0, 1);

    fprintf('\tCalculating devel kernel %s ... \n', feature_ext) ;
	
    ker = calcKernel(ker, dev_hists);

    %save kernel
    fprintf('\tSaving kernel ''%s''.\n', kerPath) ;
    ssave(kerPath, '-STRUCT', 'ker', '-v7.3');

    %save kernel descriptors (without kernel matrix)
    ker = rmfield(ker, 'matrix') ;

    % optionally save the kernel descriptor (includes gamma for the RBF)
    if ~isempty(ker.descname)
      
      fprintf('\tSaving kernel descriptor ''%s''.\n', kerDescrPath) ;
      ssave(kerDescrPath, '-STRUCT', 'ker', '-v7.3') ;
    end    
else
    fprintf('Skipped calculating devel kernel %s \n', feature_ext);
	fprintf('Loading dev_hists kernel %s \n', feature_ext);
	load(devHistPath, 'dev_hists');
	
	if exist(kerDescrPath),
        load(kerDescrPath);
    end
end
%% kernel on train-test pat

fprintf('\tLoading test features for kernel %s ... \n', feature_ext) ;

%use kernel with paramters from training


testHistPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, ker.testHists);

if exist(testHistPath),
    load(testHistPath);
else
    test_hists = calker_load_testdata(proj_name, exp_name, ker);
    save(testHistPath, 'test_hists', '-v7.3');
end


num_part = ceil(size(test_hists, 2)/10000);
cols = fix(linspace(1, size(test_hists, 2) + 1, num_part+1));

%fprintf('Scaling data before cal kernel...\n');
%test_hists = scaledata(test_hists, 0, 1);

% cal test kernel using num_part partition

fprintf('Calculating test kernel %s with %d partition \n', feature_ext, num_part);

for jj = 1:num_part,
	sel = [cols(jj):cols(jj+1)-1];
	part_name = sprintf('%s_%d_%d', ker.testname, cols(jj), cols(jj+1)-1);
	kerPath = sprintf('%s/kernels/%s.mat', calker_exp_dir, part_name);

	if ~checkFile(kerPath)
		
		fprintf('\tCalculating test kernel %s [range: %d-%d]... \n', feature_ext, cols(jj), cols(jj+1)-1) ;
		testKer = calcKernel(ker, dev_hists, test_hists(:, sel));
		%save test kernel
		fprintf('\tSaving kernel ''%s''.\n', kerPath) ;
		ssave(kerPath, '-STRUCT', 'testKer', '-v7.3') ;

	else
		kerPath
		fprintf('Skipped calculating test kernel %s [range: %d-%d] \n', feature_ext, cols(jj), cols(jj+1)-1);
	end

end



%% clean up
clear dev_hists;
clear test_hists;
clear kernel;
clear testKer;
    

end