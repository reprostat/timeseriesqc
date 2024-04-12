function varargout = run_timeseriesqc(cmd, varargin)
% Wrapper function for timeseriesqc routines

switch cmd,
    case 'run'
        subfun = varargin{1};
        job    = varargin{2};
        switch subfun
            case 'timeseriesqc'
                for k = 1:numel(job.imgs)
                    p = spm_fileparts(deblank(job.imgs{k}{1}(1,:)));
                    if job.vf
                        flags = 'mv';
                    else
                        flags = 'm';
                    end
                    imgs = char(job.imgs{k});
                    qc = timeseriesqc(imgs,flags); % old [td globals slicediff]
                    out.fnQC{k} = fullfile(p,'timeseriesqc.mat');
                    save(out.fnQC{k}, 'qc');
                end
                out.qc = qc;
                varargout{1} = out;
            case 'timeseriesqc_plot'
                flags = ''; args = {};
                fgs(1) = spm_figure('GetWin', 'Graphics1'); spm_figure('Clear',fgs(1),'Graphics1');
                fgs(2) = spm_figure('GetWin', 'Graphics2'); spm_figure('Clear',fgs(2),'Graphics2');
                for k = 1:numel(job.fnQC)
                    if isfield(job,'mocopar')
                        flags = 'r';
                        args = job.mocopar(k);
                    end
                    h = timeseriesqc_plot(job.fnQC{k}, fgs, flags, args{:});
                    spm_figure('NewPage', fgs(1));
                    spm_figure('NewPage', fgs(2));
                end
                if job.doprint
                    print(fgs(1),'-djpeg','-r150','-noui',spm_file(job.fnQC{k},'suffix','_01','ext','jpg'));
                    print(fgs(2),'-djpeg','-r150','-noui',spm_file(job.fnQC{k},'suffix','_02','ext','jpg'));
                end
        end

    case 'defaults'
        if nargin == 2
            varargout{1} = local_defs(varargin{1});
        else
            local_defs(varargin{1:2});
        end
end

function varargout = local_defs(defstr, defval)
persistent defs;
if isempty(defs)
    defs.vf = false;
    defs.doprint = true;
end
if nargin == 1
    varargout{1} = defs.(defstr);
else
    defs.(defstr) = defval;
end
