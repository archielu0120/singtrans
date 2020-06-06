% let g:neoformat_python_autopep8 = {
%         \ 'exe': 'autopep8',
%         \ 'args': ['-s 4', '-E'],
%         \ 'replace': 1 " replace the file, instead of updating buffer (default: 0),
%         \ 'stdin': 1, " send data to stdin of formatter (default: 0)
%         \ 'valid_exit_codes': [0, 23],
%         \ 'no_append': 1,
%         \ }

function demo()
    run 'addPath.m';
    use(1, 25, 34);
end

function use(song_id, t_start, t_end)
    timeInterval = [t_start, t_end];
    
    fea = jsondecode(fileread(sprintf(...
        './MIR-ST500/%d/%d_feature.json', song_id, song_id)));
    %     web(deblank(fileread(sprintf(...
    %         './MIR-ST500/%d/%d_link.txt', song_id, song_id))));
    len = length(fea.vocal_pitch);
    pv.pitch = fea.vocal_pitch;
    pv.time = fea.time;

    gtnote = noteFileRead(sprintf(...
        './MIR-ST500/%d/%d_groundtruth.txt', song_id, song_id));
%     note = noteSubsequence(note, timeInterval, 1);
    gtnote.pitch = gtnote.pitch';
    gtnote.start = gtnote.start';
    gtnote.duration = gtnote.duration';
   
    opt = pv2note('defaultOpt');
    opt.method = 'simple';
    prednote = pv2note(pv, opt);
    
    a = 1000;
    b = 1800;
    gtpv = zeros(len); % ground-thuth pitch vector
    for i = 1:length(gtnote.pitch)
        gtpv(fix(gtnote.start(i)/0.032)+1 : ...
             fix((gtnote.start(i)+gtnote.duration(i))/0.032+1)) = ...
                gtnote.pitch(i);
    end
    predpv = zeros(len); % predicted pitch vector
    for i = 1:length(prednote.pitch)
        predpv(fix(prednote.start(i)/0.032)+1 : ...
             fix((prednote.start(i)+prednote.duration(i))/0.032+1)) = ...
                prednote.pitch(i);
    end
    target_fea = fea.spectral_rolloff;
    sca = mean(target_fea) / mean(pv.pitch);
    sca = 1;
    % plot: blue, orange, yellow
%     plot(a:b, pv.pitch(a:b)*sca, a:b, target_fea(a:b),...
%         a:b, gtpv(a:b)*sca);
    plot(a:b, pv.pitch(a:b)*sca, a:b, gtpv(a:b)*sca, a:b, predpv(a:b));
    ylim([50 70]);

    % full song pv
    % opt = pvPlot('defaultOpt');
    % opt.showPlayButton = 0;
    % pvPlot(pv, opt);

%     timeInterval = [t_start t_end];
%     pvsub = pvSubsequence(pv, timeInterval);
%     pvsub.name = 'Singing pitch of the first phrase';
%     opt = pvPlot('defaultOpt');
%     pvPlot(pvsub, opt);

    % notePlay(note);

    % note = noteFileRead('predict.txt');
    % note = noteSubsequence(note,timeInterval,1);
    % notePlot(note);
end
