function hs = timeseriesqc_plot(fnQC,fgs,flags, varargin)
% timeseriesqc_plot - plots timeseries QC output
% FORMAT timeseriesqc_plot(fnQC,fgs,flags, varargin)
%
% fnQC       - time difference file name - mat file with diff parameters
% fg         - figure handle of figure to display in [spm graphics]
% flags      - zero or more of
%              'r' - display realignment parameters
%              These are either passed as filename in next arg or
%              collected from the same directory as the above .mat file
%              or selected via the GUI if not present

if nargin < 1
    fnQC = spm_select(1, 'timeseriesqc.mat', 'Select timeseries QC output');
end
if nargin < 2
    fgs = [];
end
if isempty(fgs)
    fgs(1) = spm_figure('Create', 'Graphics1'); spm_figure('Clear',fgs(1),'Graphics1');
    fgs(2) = spm_figure('Create', 'Graphics2'); spm_figure('Clear',fgs(2),'Graphics2');
end
if nargin < 3
    flags = '';
end
if isempty(flags)
    flags = ' ';
end

if any(flags == 'r')
    % plot realignment params
    if ~isempty(varargin)  % file name has been passed (maybe)
        fs(1).name = varargin{1};
    else
        % need to get realignment parameter file
        rwcard = 'realignment*.txt';
        [pn fn ext] = fileparts(fnQC);
        % check for realignment file in directory
        fs = dir(fullfile(pn, rwcard));
        if length(fs) > 1 || isempty(fs)
            % ask for realignment param file
            rfn = spm_get([0 1], rwcard, 'Realignment parameters');
            if ~isempty(rfn)
                fs(1).name = rfn;
            end
        end
    end
    if ~isempty(fs)
        % we do have movement parameters
        mparams = spm_load(fs(1).name);
        subpno = 5;
    else
        % we don't
        mparams = [];
        subpno = 4;
    end
else
    subpno = 4;
end

load(fnQC,'qc')
imgno = numel(qc.global.mean);
zno =   size(qc.slice.mean,2);
mom = mean(qc.global.mean);
sslicediff = qc.slice.svd/mom;
slicemean_norm = qc.slice.mean - repmat(mean(qc.slice.mean,1),size(qc.slice.mean,1),1);

datatoplot = {...
    {{@plot}              2:imgno       qc.global.svd/mom  '-' 'Volume' 'Scaled variance'}             {{@imagesc @colorbar} 1:imgno   1:zno slicemean_norm'        'Volume' 'Scaled mean slice intensity'};...
    {{@imagesc @colorbar} 2:imgno 1:zno sslicediff'            'Volume' 'Scaled slice variance'}       {{@imagesc @colorbar} 2:imgno-1 1:zno log(qc.slice.fft)'     'Number of cycles in timecourse' 'FFT of slice intensity [log]'};...
    {{@plot}              1:imgno       qc.global.mean/mom '-' 'Volume' 'Scaled mean voxel intensity'} {{@plot}              2:imgno-1       log(qc.global.fft) '-' 'Number of cycles in timecourse' 'FFT of mean intensity [log]'};...
    };

hs = [];
tickstep = round(imgno/100)*10;
dxt = tickstep:tickstep:imgno;

for m = 1:size(datatoplot,2)
    figure(fgs(m));

    for p = 1:size(datatoplot,1)
        h1 = axes('position', [.1 1-(.7+p-1)/subpno .6958 .65*1/subpno]);
        h2 = datatoplot{p,m}{1}{1}(datatoplot{p,m}{2:4});
        axis([0.5 imgno+0.5 -Inf Inf]);
        set(h1,'xtick',dxt);
        xlabel(datatoplot{p,m}{5});
        ylabel(datatoplot{p,m}{6});
        if strcmp(func2str(datatoplot{p,m}{1}{1}),'imagesc'), colormap('jet'); end
        if numel(datatoplot{p,m}{1}) > 1
            pos = get(h1,'position');
            datatoplot{p,m}{1}{2}();
            set(h1,'position',pos);
        end
        hs  = [hs; h2];
    end

    if m == 1
        axes('position', [.1 1-3.7/subpno .6958 .65*1/subpno]);
        mx = max(sslicediff);
        mn = min(sslicediff);
        avg = mean(sslicediff);
        h2 = errorbar(1:zno,avg,mn,mx,'r*');
        set(h2,'MarkerEdgeColor','k');
        xlabel('Slice');
        ylabel('Slice variance');
        legend(sprintf('Mean\nMin-Max'),'Location','Best');
        hs  = [hs; h2];
    end

    % realignment params
    if any(flags == 'r')
        axes('position', [.1 1-4.7/subpno .6958 .65*1/subpno]);
        h2 = plot(mparams(:,1:3)); % translation only
        legend('x translation','y translation','z translation','Location','Best')
        xlabel('image');
        ylabel('translations [mm]');
        hs  = [hs; h2];
    end

    % and label with first image at bottom
    cp = get(gca,'Position');
    axes('Position', [0 0 1 1], 'Visible', 'off');
    img1  = deblank(qc.imgs(1,:));
    text(0.5,cp(2)/2.5,{'First image:',img1},'HorizontalAlignment','center');
end
