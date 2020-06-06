function [note, segment, mappedPv]=pv2note(pv, opt, showPlot)
% Note segmentation on a given pitch vector
%
%	Usage:
%		note = pv2note(pv, opt, showPlot)
%
%	Description:
%		note = pv2note(pv, opt, showPlot) returns the note after performing note segmentation over a given pitch vector.
%			pv: The given object of pitch vector, usually generated by pitch tracking (pitchTrack.m, for example)
%			opt: Options for the function
%				opt.method:
%					'simple': a simple method
%					'dp': method of DP which minimize deviation to note mean
%					'hmm': method of HMM which maximize path of state/transition probability
%				opt.frameRate: frame rate (or pitch rate)
%				opt.frameDuration: frame duration in ms (default to be 32 ms)
%				opt.minPitchError: Minimum pitch error (min. pitch deviation for each pitch point) within a note
%				opt.minNoteDuration: Minimum of note duration
%			showPlot: 1 for plotting
%			note: The output object of note vector, including pitch (in semitone) and duration (in sec).
%
%	Example:
%		pv.pitch=[55.79;55.79;55.79;55.79;55.79;55.79;55.79;56.01;56.24;56.47;56.47;56.47;0;0;0;0;0;60.62;60.92;61.22;61.22;61.22;61.22;61.22;0;0;0;0;0;0;63.14;63.49;63.49;63.49;63.49;63.84;64.56;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;64.56;64.93;64.93;65.7;66.92;67.79;67.79;67.79;67.79;67.79;67.35;65.7;65.31;65.31;65.31;65.31;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.93;64.56;64.56;0;0;0;0;0;0;0;0;0;0;0;0;60.62;60.62;60.92;60.92;61.22;61.84;62.48;62.48;62.48;62.48;0;0;0;60.92;60.92;60.92;60.92;60.92;60.92;60.92;60.92;60.92;60.92;0;0;0;0;59.49;59.49;59.49;59.49;59.76;60.04;60.33;60.62;60.92;60.92;60.92;61.22;61.22;61.22;60.92;60.92;60.92;60.92;60.92;60.92;60.92;60.92;60.62;60.33;60.04;59.76;59.49;59.76;59.76;59.76;60.04;60.33;60.33;60.33;60.33;60.04;59.76;58.68;58.16;57.91;57.91;57.91;57.66;57.42;57.17;56.94;56.7;56.47;56.24;56.24;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;56.01;0;0;0;0;0;0];
%		pv.time=[0.016;0.048;0.08;0.112;0.144;0.176;0.208;0.24;0.272;0.304;0.336;0.368;0.4;0.432;0.464;0.496;0.528;0.56;0.592;0.624;0.656;0.688;0.72;0.752;0.784;0.816;0.848;0.88;0.912;0.944;0.976;1.008;1.04;1.072;1.104;1.136;1.168;1.2;1.232;1.264;1.296;1.328;1.36;1.392;1.424;1.456;1.488;1.52;1.552;1.584;1.616;1.648;1.68;1.712;1.744;1.776;1.808;1.84;1.872;1.904;1.936;1.968;2;2.032;2.064;2.096;2.128;2.16;2.192;2.224;2.256;2.288;2.32;2.352;2.384;2.416;2.448;2.48;2.512;2.544;2.576;2.608;2.64;2.672;2.704;2.736;2.768;2.8;2.832;2.864;2.896;2.928;2.96;2.992;3.024;3.056;3.088;3.12;3.152;3.184;3.216;3.248;3.28;3.312;3.344;3.376;3.408;3.44;3.472;3.504;3.536;3.568;3.6;3.632;3.664;3.696;3.728;3.76;3.792;3.824;3.856;3.888;3.92;3.952;3.984;4.016;4.048;4.08;4.112;4.144;4.176;4.208;4.24;4.272;4.304;4.336;4.368;4.4;4.432;4.464;4.496;4.528;4.56;4.592;4.624;4.656;4.688;4.72;4.752;4.784;4.816;4.848;4.88;4.912;4.944;4.976;5.008;5.04;5.072;5.104;5.136;5.168;5.2;5.232;5.264;5.296;5.328;5.36;5.392;5.424;5.456;5.488;5.52;5.552;5.584;5.616;5.648;5.68;5.712;5.744;5.776;5.808;5.84;5.872;5.904;5.936;5.968;6;6.032;6.064;6.096;6.128;6.16;6.192;6.224;6.256;6.288;6.32;6.352;6.384;6.416;6.448;6.48];
%		gtNote.start=[0.1292 0.55 1 2.14 2.559 3.45 3.829 4.25 4.65 5.038 5.5 5.889];
%		gtNote.duration=[0.3906 0.2573 0.5 0.3958 0.4563 0.3792 0.4209 0.3781 0.35 0.3886 0.3501 0.4229];
%		gtNote.pitch=[56 61 65 68 65 63 61 61 61 61 58 56];
%		opt=pv2note('defaultOpt');
%		opt.method='simple';
%		opt.gtNote=gtNote;
%		note=pv2note(pv, opt, 1);
%
%	See also noteSegmentViaDp, lineSegmentViaDp.

%	Roger Jang, 20060527, 20070531, 20121029, 20200531

if nargin<1, selfdemo; return; end
if ischar(pv) && strcmpi(pv, 'defaultOpt')    % Set the default options
	note.frameRate=8000/256;
	note.minPitchError=0.9;
	note.minNoteDuration=0.5;	% for method of 'simple';
	note.minNoteDuration=0;		% for method of 'dp' since it's not working now
	note.method='dp';
	note.anchoredEnd=1;		% Used in noteSegmentViaDp.m
	note.roundToInteger=1;
	note.gtNote=[];
	return
end
if nargin<2||isempty(opt), opt=feval(mfilename, 'defaultOpt'); end
if nargin<3, showPlot=0; end

segment=segmentFind(pv.pitch);	% Segments are separated by silence

switch(lower(opt.method))
	case 'simple'
		for j=1:length(segment)
			thePv=pv.pitch(segment(j).begin:segment(j).end);	% PV in this segment, to be segmened into notes
			note=[];	% We are going to construct notes sequentially within this segment
			pvInNote=thePv(1);		% PV in the current note
			k=1;	% Note index within current segment
			for i=2:length(thePv)
				noteDuration=length(pvInNote)/opt.frameRate;
				pvInNote2=[pvInNote, thePv(i)];		% Add the next pitch point to the current note for testing
				meanPitchError=mean(abs(pvInNote2-median(pvInNote2)));	% Error after adding the next pitch point
				if meanPitchError>opt.minPitchError && noteDuration>opt.minNoteDuration	% Create a new note if the pitch diff. is high and note duration is long...
					note(k).pitch=median(pvInNote);
					note(k).duration=noteDuration;
					if k==1
						note(k).pvIndex=1:i-1;
					else
						note(k).pvIndex=note(k-1).pvIndex(end)+1:i-1;
					end
					pvInNote=thePv(i);	% First pitch point in the next note
					k=k+1;
				else
					pvInNote=pvInNote2;
				end
			end
			% === Process the last note
			note(k).pitch=median(pvInNote);
			note(k).duration=length(pvInNote)/opt.frameRate;
			if k==1
				note(k).pvIndex=1:length(thePv);
			else
				note(k).pvIndex=note(k-1).pvIndex(end)+1:length(thePv);
			end
			% === Merge the last two notes if the last note is too short
			if note(end).duration<opt.minNoteDuration && length(note)>1
			%	if length(note)==1, fprintf('Error: Found a single note that is too short!'); keyboard; end
				note(end-1).pvIndex=[note(end-1).pvIndex, note(end).pvIndex];
				note(end)=[];
				note(end).pitch=median(thePv(note(end).pvIndex));
				note(end).duration=length(note(end).pvIndex)/opt.frameRate;
			end
			% === Assign to segment
			segment(j).note=note;
		end
	case 'dp'
		% Given a fixed number of notes, we can use DP to find the optimum assignment of pitch to note.
		% Hence for a given L-1 distance threshold, we can increase the numbrer of notes incrementally,
		% until the distance returned by DP is smaller than the threshold.
		for i=1:length(segment)
			thePv=pv.pitch(segment(i).begin:segment(i).end);
            thePvFlux = pv.flux(segment(i).begin:segment(i).end);
			opt2=noteSegmentViaDp('defaultOpt');
			opt2.minNoteDuration=0.0001;	% Don't care
			opt2.frameRate=opt.frameRate;
			for j=1:length(thePv)	% Fin the min. no. of segments that has a normalizedMinDist smaller than opt.minPitchError
				opt2.noteCount=j;	% Increase the note number sequentially until the error is small.
				[normalizedMinDist, dtwPath, dtwTable, note]=noteSegmentViaDp(thePv, thePvFlux, opt2, 0);
			%	keyboard
			%	fprintf('i=%d/%d, j=%d/%d\n', i, length(segment), j, length(thePv));
				if normalizedMinDist<=opt.minPitchError, break; end		% Break if the error is small enough
			end
			segment(i).note=note;
		end
	case 'hmm'		% DP based on HMM (implemented as dpOverMapMex)
		for i=1:length(segment)
			thePv=pv.pitch(segment(i).begin:segment(i).end);
			hmmModel=htHmmModelGen(thePv);	% To identify proper semitone range
			opt2=htHmmEval('defaultOpt', length(hmmModel.gmm), 8000/256);
			showThisPlot=0;
			[note, dpPath]=htHmmEval(thePv, hmmModel, opt2, showThisPlot);
			segment(i).note=note;
			if showThisPlot
				fprintf('i=%d/%d\n', i, length(segment));
				fprintf('Press any key to continue...'); pause; fprintf('\n');
			end
		end
	otherwise
		error('Unknown method %s in %s!', opt.method, mfilename);
end

% Change segment(i).note(j).pvIndex to global index instead of local index within segment(i)
% Also append start time to note structure
for i=1:length(segment)
	for j=1:length(segment(i).note)
		segment(i).note(j).pvIndex=segment(i).note(j).pvIndex+segment(i).begin-1;
		segment(i).note(j).start=pv.time(segment(i).note(j).pvIndex(1)) - (pv.time(2)-pv.time(1))/2;
	end
end
note=[segment.note];

if nargin>2
	mappedPv=0*pv.pitch;
	for i=1:length(note)
		mappedPv(note(i).pvIndex)=note(i).pitch;
	end
end

% Convert the note to the new format. This should be modified eventually.
note2.pitch=[note.pitch];
note2.start=[note.start];
note2.duration=[note.duration];
note=note2;
% Round the pitch to the nearest integer
if opt.roundToInteger
	note.pitch=round(note.pitch);
end

if showPlot
	notePlot(note);
	temp=pv.pitch; temp(temp==0)=nan;
	line(pv.time, temp, 'color', 'k', 'marker', '.');
	title(sprintf('Method=%s, number of detected notes=%d', opt.method, length([segment.note])));
	% Place the PV-play button
	auPv=pv2au(pv);
	audioPlayButton(auPv, [20, 10, 100, 20], 'Play PV');
	% Place the note-play button
	auNote=note2au(note);
	audioPlayButton(auNote, [140, 10, 100, 20], 'Play detected notes');
	if ~isempty(opt.gtNote)
		opt2=notePlot('defaultOpt');
		opt2.color='m';
		opt2.buttonPosition=[260, 10, 100, 20];
		opt2.buttonLabel='Play GT notes';
		gtNote=opt.gtNote; gtNote.pitch=gtNote.pitch-0.1;	% Shift slightly to avoid overlap with other curves
		notePlot(gtNote, opt2);
	end
end

% ====== Self demo
function selfdemo
mObj=mFileParse(which(mfilename));
strEval(mObj.example);