function [ code ] = fc_encode( feats, codebook, low_proj )
%KCBENCODE Summary of this function goes here
%   Detailed explanation goes here
	
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
	
	% update 
	% now apply kernel map 
    
    code = sign(code) .* sqrt(abs(code));        
 
    % now post-normalize whole code
    % pcode = pcode/norm(pcode,2);
    
end

