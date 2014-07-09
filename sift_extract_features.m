function [frames, descrs] = sift_extract_features( img_path, sift_algo, param )
	%param
	% sift_algo is dsift --> param is nSize
	% sift_algo is phow --> param is color type for vl_phow: GRAY (PHOW-gray), RGB, HSV, and OPPONENT (PHOW-color).
	% sift_algo is covdet --> param is hessian
	% sift_algo is fspace --> param is hesaff, note: im is image path
	
	%% SIFT parameters
	switch (sift_algo),
		case 'dsift'
			
			if exist('param', 'var'),
				obj.nSize = param;
			else
				obj.nSize = 6;
			end
			try
				im = imread(img_path);
				[frames, descrs] = vl_dsift(single(rgb2gray(im)), 'step', obj.nSize);
			catch
				frames = [];
				descrs = [];
			end
			
		case 'covdet'
			if exist('param', 'var'),
				obj.method = param;
			else
				obj.method = 'dog';
			end
			
			try
				im = imread(img_path);
				[frames, descrs] = vl_covdet(single(rgb2gray(im)), 'method', obj.method);
			catch
				frames = [];
				descrs = [];
			end
			
			%% Update Jul 9, support rootsift
			if ~isempty(descrs),
				sift = double(descrs);
				descrs = single(sqrt(sift./repmat(sum(sift), 128, 1)));
			end
				
		case 'phow'
            obj.verbose = false;
            obj.sizes = [4 6 8 10];
            obj.fast = true;
            obj.step = 3;
			if exist('param', 'var'),
				obj.color = param;
			else
				obj.color = 'gray';
			end
            obj.contrast_threshold = 0.005;
            obj.window_size = 1.5;
            obj.magnif = 6;
            obj.float_descriptors = false;
			
			try
				im = imread(img_path);
				im = standardizeImage(im); 
				[frames, descrs] = vl_phow(im, 'Verbose', obj.verbose, ...
					'Sizes', obj.sizes, 'Fast', obj.fast, 'step', obj.step, ...
					'Color', obj.color, 'ContrastThreshold', obj.contrast_threshold, ...
					'WindowSize', obj.window_size, 'Magnif', obj.magnif, ...
					'FloatDescriptors', obj.float_descriptors);
			catch
				frames = [];
				descrs = [];
			end
			
		case 'fspace' %param = hesaff
			tmpdir = '/net/per900a/raid0/plsang/tmp/sift';
			fspace_bin = '/net/per900a/raid0/plsang/tools/featurespace/compute_descriptors_64bit.ln';
			[~, fname, fext] = fileparts(img_path);
			[~, tmpname] = fileparts(tempname);
			tmp_feat_file = sprintf('%s/%s.%s.feat', tmpdir, fname, tmpname);
			%<duong dan den file anh input>
			cmd = sprintf('%s -%s -sift -noangle -i %s -o1 %s', fspace_bin, param, img_path, tmp_feat_file);
			system(cmd);
			[frames, descrs] = load_fspace_feature(tmp_feat_file);
			
			%%% applying root sift
			if ~isempty(descrs),
				sift = double(descrs);
				descrs = single(sqrt(sift./repmat(sum(sift), 128, 1)));
			end

			delete(tmp_feat_file);
		otherwise
			error('Unknow sift algorithm!!!\n');
	end
	
end

function im = standardizeImage(im)

	if ndims(im) == 3
		im = im2single(im);
	elseif ndims(im) == 2
		im_new = cat(3,im,im);
		im_new = cat(3,im_new,im);
		im = im_new;
		im = im2single(im);
		clear im_new;
	else
		error('Input image not valid');
	end

end

