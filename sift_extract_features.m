function [frames, descrs] = sift_extract_features( im, sift_algo, param )
	%param
	% sift_algo is dsift --> param is nSize
	% sift_algo is phow --> param is color type for vl_phow: GRAY (PHOW-gray), RGB, HSV, and OPPONENT (PHOW-color).

	%% SIFT parameters
	switch (sift_algo),
		case 'dsift'
			if exist('param', 'var'),
				obj.nSize = param;
			else
				obj.nSize = 6;
			end
			[frames, descrs] = vl_dsift(single(rgb2gray(im)), 'step', obj.nSize);
			
		case 'covdet'
			if exist('param', 'var'),
				obj.method = param;
			else
				obj.method = 'dog';
			end
			[frames, descrs] = vl_covdet(single(rgb2gray(im)), 'method', obj.method);
				
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
			
			im = standardizeImage(im); 
			[frames, descrs] = vl_phow(im, 'Verbose', obj.verbose, ...
				'Sizes', obj.sizes, 'Fast', obj.fast, 'step', obj.step, ...
				'Color', obj.color, 'ContrastThreshold', obj.contrast_threshold, ...
				'WindowSize', obj.window_size, 'Magnif', obj.magnif, ...
				'FloatDescriptors', obj.float_descriptors);
				
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

