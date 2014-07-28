function calker_late_fusion(proj_name, test_pat, suffix)

	exp_name = 'trecvidmed13-100000';
	
	if ~exist('suffix', 'var'),
		suffix = '--calker-v7.1';
	end
	
	ker.proj_dir = '/net/per610a/export/das11f/plsang';
	
	addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker/support');
	addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');
	addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox');

	event_list = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/trecvidmed13.events.ps.lst';
	fh = fopen(event_list, 'r');
	infos = textscan(fh, '%s %s', 'delimiter', ' >.< ', 'MultipleDelimsAsOne', 1);
	fclose(fh);
	events = infos{1};
			
	ker_names = struct;
	ker_names.('mbh_fc_pca') = 'densetrajectory.mbh.cb256.fc.pca.l2';
	%ker_names.('mbh_fc') = 'densetrajectory.mbh.cb256.fc.l2';
	%ker_names.('mbh_soft') = 'densetrajectory.mbh.cb4000.soft.l2';
	%ker_names.('multiseg_mbh_fc') = 'fusion-multiseg.mbh_fc';
	%ker_names.('multiseg_mbh_soft') = 'fusion-multiseg.mbh_soft';
	
	ker_names.('sift_fc_pca') = 'covdet.hessian.sift.cb256.devel.fisher.pca.l2';
	%ker_names.('sift_soft') = 'covdet.hessian.sift.cb4000.devel.soft.l2';
	%ker_names.('multiseg_sift_fc') = 'fusion-multiseg.sift_fc';
	%ker_names.('multiseg_sift_soft') = 'fusion-multiseg.sift_soft';
	
	%ker_names.('mfcc_fc') = 'mfcc.rastamat.cb256.fc.l2';
	%ker_names.('mfcc_soft') = 'mfcc.rastamat.cb4000.soft.l2';
				
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker', ker.proj_dir, proj_name, exp_name);
	
	fused_ids = fieldnames(ker_names);
	fusion_name = 'fusion';
	for ii=1:length(fused_ids),
		fusion_name = sprintf('%s.%s', fusion_name, fused_ids{ii});
	end
	
	output_file = sprintf('%s/%s%s/scores/%s/%s.scores.mat', calker_exp_dir, fusion_name, suffix, test_pat, fusion_name);
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	fused_scores = struct;
	for ii=1:length(events),
		event_name = events{ii};
		fprintf('Fusing for event [%s]...\n', event_name);
		for jj = 1:length(fused_ids),
			ker_name = ker_names.(fused_ids{jj});
			fprintf(' -- [%d/%d] kernel [%s]...\n', jj, length(fused_ids), ker_name);
			scorePath = sprintf('%s/%s%s/scores/%s/%s.video.scores.mat', calker_exp_dir, ker_name, suffix, test_pat, ker_name);
			
			if ~exist(scorePath, 'file');
				scorePath = sprintf('%s/%s%s/scores/%s/%s.scores.mat', calker_exp_dir, ker_name, suffix, test_pat, ker_name);
			end
			
			if ~exist(scorePath, 'file');
				error('File not found! [%s]', scorePath);
			end
			
			scores = load(scorePath);
			if isfield(fused_scores, event_name),			
				fused_scores.(event_name) = [fused_scores.(event_name); scores.(event_name)];
			else
				fused_scores.(event_name) = scores.(event_name);
			end
		end
		fused_scores.(event_name) = mean(fused_scores.(event_name)); %scores: 1 x number of videos
	end
	
	scores = fused_scores;
	ssave(output_file, '-STRUCT', 'scores');
	
	ker.feat = fusion_name;
	ker.name = fusion_name;
	ker.suffix = suffix;
	ker.test_pat = test_pat;
	
	fprintf('Calculating MAP...\n');
	calker_cal_map(proj_name, exp_name, ker, events);
end