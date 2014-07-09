function code = sift_do_encoding(enc_type, feats, codebook, kdtree, low_proj)
	switch enc_type,
		case 'hard'
			max_comps = 500;			
			if max_comps ~= -1
				% using ann...
				codeids = vl_kdtreequery(kdtree, codebook, feats, ...
					'MaxComparisons', max_comps);
			else
				% using exact assignment...
				[~, codeids] = min(vl_alldist(codebook, feats), [], 1);
			end
			
			code = vl_binsum(zeros(size(codebook, 2), 1), 1, double(codeids));

		case 'soft'
			
			max_comps = 500;
			num_nn = 5;
			sigma = 45;
			kcb_type = 'unc';
								
			if max_comps ~= 1,
				% using ann...
				code = featpipem.lib.KCBEncode(feats, codebook, num_nn, ...
					sigma, kdtree, max_comps, kcb_type, false);
			else
				% using exact assignment...
				code = featpipem.lib.KCBEncode(feats, codebook, num_nn, ...
					sigma, [], [], kcb_type, false);
			end
			
		case 'fisher'
		
			fisher_params.grad_weights = false;		% "soft" BOW
			fisher_params.grad_means = true;		% 1st order
			fisher_params.grad_variances = true;	% 2nd order
			fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
			fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
					
			cpp_handle = mexFisherEncodeHelperSP('init', codebook, fisher_params);
			
			% Update Aug 1st, 2013 supports PCA
			if ~isempty(low_proj)
				feats = low_proj * feats;   
			end
			
			%important updates: feats must be class of single
			code = mexFisherEncodeHelperSP('encode', cpp_handle, single(feats));
			
			mexFisherEncodeHelperSP('clear', cpp_handle);
			
			% now apply kernel map 
			code = sign(code) .* sqrt(abs(code));  
			
			% Update Jul 8
			code = code / norm(code, 2);
			
		otherwise
		
	end
end