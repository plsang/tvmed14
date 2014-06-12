function pcode = sift_encode_spm(enc_type, imsize, frames, feats, codebook, kdtree, low_proj)
	%COMPUTE Pool features using the spatial pyramid match kernel
	%imsize:
	%feats: 128 x NumOfPoints: indexes of feature points
	%frames: 2  x NumOfPoints
	%tree codebook

	%% update may 28th: normalize each region separately
	obj.subbin_norm_type = 'none'; % normalization to be applied to SPM subbins ('l1' or 'l2' or 'none')
	obj.norm_type = 'none'; % normalization to be applied to whole SPM vector
	obj.pool_type = 'sum'; % SPM pooling type (either 'sum' or 'max')
	obj.kermap = 'none'; % additive kernel map to be applied to SPM (either 'none' or 'homker')
	obj.quad_divs = 2;
	obj.horiz_divs = 3; %3;
	obj.veriz_divs = 3; %3;
	obj.codebook_size = size(codebook, 2);
	
    % check pool type is valid
    if ~strcmp(obj.pool_type, 'sum') && ~strcmp(obj.pool_type, 'max')
        error('pool_type must be either ''sum'' or ''max''');
    end

    % check bin levels
    if mod(log2(obj.quad_divs),1)
        error('quad_divs must be a power of 2');
    end
    bin_quads_count = obj.quad_divs*obj.quad_divs;
    bin_quad_levels = 1;
    bin_div_tmp = obj.quad_divs;
    while bin_div_tmp ~= 2
        bin_div_tmp = bin_div_tmp/2;
        bin_quad_levels = bin_quad_levels + 1;
        bin_quads_count = bin_quads_count + bin_div_tmp*bin_div_tmp;
    end
    clear bin_div_tmp;
    
    bin_count = bin_quads_count + obj.horiz_divs + obj.veriz_divs + 1;
    
    pcode = zeros(obj.codebook_size, bin_count, 'single');
    
    % first compute for finest 'quarter' bins
    h_unit = imsize(1) / obj.quad_divs;
    w_unit = imsize(2) / obj.quad_divs;
    y_bin = ceil(frames(2,:) / h_unit);
    x_bin = ceil(frames(1,:) / w_unit);
    
    %feats_sel_num = zeros(obj.quad_divs ^ 2, 1);
    code_idx = 0;
    
    for sx_bin = 1:obj.quad_divs
        for sy_bin = 1:obj.quad_divs
            
            code_idx = code_idx + 1;
            
            %feats_sel = feats((y_bin == sy_bin) & (x_bin == sx_bin));
			feats_sel = feats(:, (y_bin == sy_bin) & (x_bin == sx_bin));
            %feats_sel_num(code_idx) = size(feats_sel, 2);
			
            if ~isempty(feats_sel)
				%code = vl_binsum(zeros(obj.codebook_size, 1), 1, double(feats_sel));
				%code = kcbencode(feats_sel, codebook, kdtree);
				
				code = sift_do_encoding(enc_type, feats_sel, codebook, kdtree, low_proj);
				
                %code = obj.encoder_.encode(feats_sel);				
                if nnz(isnan(code)), 
					warning('--- Code contains NaNs'); 
				end
                pcode(:, code_idx) = single(code);
            else
                warning('--- SPMPool:EmptyBin','empty bin!');
            end
        end
    end
    
    % now merge to form subsequent bin levels
    if bin_quad_levels > 1
        prev_level_bin_divs = obj.quad_divs;
        prev_level_start_bin = 1;
        for i = 2:bin_quad_levels
            level_bin_divs = prev_level_bin_divs/2;
            level_start_bin = prev_level_start_bin + ...
                prev_level_bin_divs*prev_level_bin_divs;
            
            for sx_bin = 1:level_bin_divs
                for sy_bin = 1:level_bin_divs
                    xstart = 2*sx_bin-1;
                    xend = 2*(sx_bin+1)-2;
                    ystart = 2*sy_bin-1;
                    yend = 2*(sy_bin+1)-2;
                    bins_sel = zeros((xend-xstart+1)*(yend-ystart+1),1);
                    bsidx = 1;
                    for xri = xstart:xend
                        for yri = ystart:yend
                            bins_sel(bsidx) = prev_level_start_bin + ...
                                prev_level_bin_divs*(xri-1) + yri - 1;
                            bsidx = bsidx + 1;
                        end
                    end
                    
                    % combine bins
                    if strcmp(obj.pool_type,'sum')
                        pcode(:,level_start_bin + ...
                            level_bin_divs*(sx_bin-1) + ...
                            sy_bin - 1) = sum(pcode(:,bins_sel),2);
                    end
                    if strcmp(obj.pool_type,'max')
                        pcode(:,level_start_bin + ...
                            level_bin_divs*(sx_bin-1) + ...
                            sy_bin - 1) = max(pcode(:,bins_sel),[],2);
                    end
                end
            end
            
            prev_level_start_bin = level_start_bin;
            prev_level_bin_divs = level_bin_divs;
        end
    end
    
    % now compute the three horizontal bins
    if obj.horiz_divs > 0
        h_hunit = imsize(1) / obj.horiz_divs;
        h_ybin = ceil(frames(2,:) / h_hunit);
        for sy_bin = 1:obj.horiz_divs
            feats_sel = feats(:, (h_ybin == sy_bin));
            if ~isempty(feats_sel)
                %code =  obj.encoder_.encode(feats_sel);
				%code = vl_binsum(zeros(obj.codebook_size, 1), 1, double(feats_sel));
				
				%code = kcbencode(feats_sel, codebook, kdtree);
				
				code = sift_do_encoding(enc_type, feats_sel, codebook, kdtree, low_proj);
				
				if nnz(isnan(code)), warning('--- Code contains NaNs'); end
                pcode(:,bin_quads_count+sy_bin) = single(code);
            else
                warning('--- SPMPool:EmptyBin','empty bin!');
            end
        end
    end
    
    %%% now compute the three vertical bins
    if obj.veriz_divs > 0
        h_hunit = imsize(2) / obj.veriz_divs;
        h_xbin = ceil(frames(1,:) / h_hunit);
        for sx_bin = 1:obj.veriz_divs
            feats_sel = feats(:, (h_xbin == sx_bin));
            if ~isempty(feats_sel)
                %code =  obj.encoder_.encode(feats_sel);
				%code = vl_binsum(zeros(obj.codebook_size, 1), 1, double(feats_sel));
				%code = kcbencode(feats_sel, codebook, kdtree);
				
				code = sift_do_encoding(enc_type, feats_sel, codebook, kdtree, low_proj);
				
                if nnz(isnan(code)), 
					warning('--- Code contains NaNs'); 
				end
                pcode(:, bin_quads_count + obj.horiz_divs + sx_bin) = single(code);
            else
                warning('--- SPMPool:EmptyBin','empty bin!');
            end
        end
    end

    if true
        
        % now combine the first binset to make up the whole image bin
        if strcmp(obj.pool_type,'sum')
            pcode(:, end) = sum(pcode(:, 1 : obj.quad_divs ^ 2),2);% * (feats_sel_num / sum(feats_sel_num));
        elseif strcmp(obj.pool_type,'max')
            pcode(:, end) = max(pcode(:,1:obj.quad_divs^2),[],2);
        end
        
    else    
        % compute whole image encoding from scratch
		code = sift_do_encoding(enc_type, feats_sel, codebook, kdtree, low_proj);
		pcode(:, end) = single(code);
        %pcode(:, end) = obj.encoder_.encode(feats);    
    end
    
%     if nnz(pcode(:,end)) < 1, error('Code is all zeros!'); end
    
    % now normalize all sub-bins
    if strcmp(obj.subbin_norm_type, 'l2')
        
        pcode_norm = sqrt(sum(pcode .^ 2, 1));
        pcode_norm = max(pcode_norm, eps);
        pcode = bsxfun(@times, pcode, 1 ./ pcode_norm);
        
    elseif strcmp(obj.subbin_norm_type, 'l1')
        
        pcode_norm = sum(pcode, 1);
        pcode_norm = max(pcode_norm, eps);
        pcode = bsxfun(@times, pcode, 1 ./ pcode_norm);
        
    end
    
    % vectorise
    pcode = pcode(:);
    
    % now normalize whole code
    if strcmp(obj.norm_type,'l2')
        pcode = pcode/norm(pcode, 2);
    elseif strcmp(obj.norm_type,'l1')
        pcode = pcode/norm(pcode, 1);
    end
    
    % now apply kernel map if specified
    if ~isequal(obj.kermap, 'none')        
        % (note: when adding extra kernel maps, note that the getDim function
        % must also be modified to reflect the appropriate increase in code
        % dimensionality)
        if strcmp(obj.kermap,'homker')
            % chi-squared approximation
            pcode = vl_homkermap(pcode, 1, 'kchi2');
        elseif strcmp(obj.kermap,'hellinger')
            % "generalised" (signed) Hellinger kernel
            pcode = sign(pcode) .* sqrt(abs(pcode));        
        end

        % now post-normalize whole code
        if strcmp(obj.post_norm_type,'l2')
            pcode = pcode/norm(pcode,2);
        elseif strcmp(obj.post_norm_type,'l1')
            pcode = pcode/norm(pcode,1);
        end
    end

end