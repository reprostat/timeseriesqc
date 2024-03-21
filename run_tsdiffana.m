function varargout = run_tsdiffana(cmd, varargin)
% Wrapper function for tsdiffana routines

switch cmd,
    case 'run'
        subfun = varargin{1};
        job    = varargin{2};
        switch subfun
            case 'timediff'
                for k = 1:numel(job.imgs)
                    p = spm_fileparts(deblank(job.imgs{k}{1}(1,:)));
                    if job.vf
                        flags = 'mv';
                    else
                        flags = 'm';
                    end
                    imgs = char(job.imgs{k});
                    qa = timediff(imgs,flags); % old [td globals slicediff]
                    out.tdfn{k} = fullfile(p,'timediff.mat');
                    save(out.tdfn{k}, 'qa');
                end
                out.qa = qa;
                varargout{1} = out;
            case 'tsdiffplot'
                fgs(1) = spm_figure('GetWin', 'Graphics1'); spm_figure('Clear',fgs(1),'Graphics1');
                fgs(2) = spm_figure('GetWin', 'Graphics2'); spm_figure('Clear',fgs(2),'Graphics2');
                for k = 1:numel(job.tdfn)
                    h = tsdiffplot(job.tdfn{k}, fgs);
                    spm_figure('NewPage', fgs(1));
                    spm_figure('NewPage', fgs(2));
                end
                if job.doprint
                    print(fgs(1),'-djpeg','-r150','-noui',spm_file(job.tdfn{k},'suffix','_01','ext','jpg'));
                    print(fgs(2),'-djpeg','-r150','-noui',spm_file(job.tdfn{k},'suffix','_02','ext','jpg'));
                end
        end
    case 'vout'
        subfun = varargin{1};
        job    = varargin{2};
        switch subfun
            case 'timediff'
                for k = 1:numel(job.imgs)
                    dep(k) = cfg_dep;
                    dep(k).sname      = sprintf('Timeseries Analysis Data File (%d)', k);
                    dep(k).src_output = substruct('.','tdfn','()',{k});
                    dep(k).tgt_spec   = cfg_findspec({{'filter','mat', ...
                        'strtype','e'}});
                end
                varargout{1}   = dep;
            case 'tsdiffplot'
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
