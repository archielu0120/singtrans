function [normalizedMinDist, dtwPath, dtwTable, note]=noteSegmentViaDp(vec1,flux, opt, showPlot)
%noteSegmentViaDp: Note segmentation via DP
%
%	Usage:
%		[minDist, dtwPath, dtwTable, note]=noteSegmentViaDp(vec, opt, showPlot)
%
%	Description:
%		[minDist, dtwPath, dtwTable, note]=noteSegmentViaDp(vec, opt, showPlot) returns the min L1 distance after dispatch the given vec into opt.noteCount of note.
%			vec: vec for segmentation
%			opt: options for segmentation
%				opt.noteCount: no. of notes
%			minDist: min. L1 distance
%
%	Example:
%		waveFile='twinkle_twinkle_little_star.wav';
%		au=myAudioRead(waveFile);
%		pfType=1;	% 0 for AMDF, 1 for ACF
%		ptOpt=ptOptSet(au.fs, au.nbits, pfType);
%		ptOpt.method='maxPickingOverPf';
%		pv=pitchTrack(au, ptOpt);
%		pv=pv.pitch;
%		segment=segmentFind(pv);
%		vec=pv(segment(2).begin:segment(2).end);
%		showPlot=1;
%		opt=noteSegmentViaDp('defaultOpt');
%		opt.frameRate=au.fs/(ptOpt.frameSize-ptOpt.overlap);
%		opt.noteCount=4;
%		opt.minNoteDuration=0.0003;		% Don't care
%		opt.anchoredEnd=1;
%		[minDist, dtwPath, dtwTable, note]=noteSegmentViaDp(vec, opt, showPlot);
%		figure; plot((0:length(vec)-1)/opt.frameRate, vec, '.-g');	% Plot the pv and the segmented notes
%		hold on; notePlot(note, 1, 'b'); hold off
%
%	See also pv2note, lineSegmentViaDp.

%	Category: Note segmentation
%	Roger Jang, 20121101

if nargin<1, selfdemo; return; end
if ischar(vec1) && strcmpi(vec1, 'defaultOpt')	% Set the default options
	normalizedMinDist.noteCount=3;
	normalizedMinDist.minNoteDuration=0.0001;	% Don't care. To be implement later
	normalizedMinDist.frameRate=8000/256;		% For returning note duration
	normalizedMinDist.anchoredEnd=1;
	return
end
if nargin<3, showPlot=0; end

vec1=vec1(:);
vec2=1:opt.noteCount;
len1=length(vec1);
len2=length(vec2);
stdScale=45:93;		% a row vec
stdScaleCount=length(stdScale);

% ====== Construct DTW table
dtwTable=inf*ones(len1,len2);
% ====== Construct prevPos table for back tracking the optimum path
for i=1:len1
	for j=1:len2
		if nargout>1 || showPlot
			prevPos(i,j).i=-1;
			prevPos(i,j).j=-1;
		end
		prevPos(i,j).startI=-1;		% Note begin index
	end
end

% ====== Construct the first element of the DTW table
dtwTable(1,1)=0; prevPos(1,1).startI=1;
% ====== Construct the first column of the DTW table (xy view)
for j=2:len2
	dtwTable(1,j)=inf;
	prevPos(1,j).startI=-1;		% Note begin index
end
% ====== Construct the first row of the DTW table (xy view)
for i=2:len1
	thePv=vec1(1:i);
	dtwTable(i,1)=pv2noteDist(thePv, stdScale);
%	dtwTable(i,1)=sum(abs(thePv-median(thePv)));
	if length(thePv)/opt.frameRate<opt.minNoteDuration, dtwTable(i,1)=inf; end
	if nargout>1 || showPlot
		prevPos(i,1).i=i-1;
		prevPos(i,1).j=1;
	end
	prevPos(i,1).startI=1;		% Note begin index
end
% ====== Construct all the other columns of DTW table (xy view)
for i=2:len1
	for j=2:len2
		startI=prevPos(i-1,j).startI;
		if startI==-1
			dist1=inf;
		elseif startI==1
			thePv=vec1(1:i);
			dist1=pv2noteDist(thePv, stdScale);
		%	dist1=sum(abs(thePv-median(thePv)));	% 0-degree path
			if length(thePv)/opt.frameRate<opt.minNoteDuration, dist1=inf; end
		else
			thePv=vec1(startI:i);
			dist1=dtwTable(startI-1,j)+pv2noteDist(thePv, stdScale);
		%	dist1=dtwTable(startI-1,j)+sum(abs(thePv-median(thePv)));	% 0-degree path
			if length(thePv)/opt.frameRate<opt.minNoteDuration, dist1=inf; end
		end
		dist2=dtwTable(i-1, j-1)+pv2noteDist(vec1(i), stdScale);	% 45-degree path
		if ((i-prevPos(i-1,j-1).startI)/opt.frameRate<opt.minNoteDuration) | (dist2+eps>=dist1)	% ====== Take 0-degree path
			dtwTable(i,j)=dist1;
			prevPos(i,j).startI=prevPos(i-1,j).startI;
			if nargout>1 || showPlot
				prevPos(i,j).i=i-1;
				prevPos(i,j).j=j;
			end
		else			% ====== Take 45-degree path
			dtwTable(i,j)=dist2;
			prevPos(i,j).startI=i;
			if nargout>1 || showPlot
				prevPos(i,j).i=i-1;
				prevPos(i,j).j=j-1;
			end
		end
	end
end

% ====== Find the last point and the min. dist
if opt.anchoredEnd	% Anchored end
	besti=len1; bestj=len2;
	minDist=dtwTable(end, end);
else	% Free end
	besti=len1;
	[minDist, bestj]=min(dtwTable(end, :));
end
normalizedMinDist=minDist/length(vec1);

if nargout>1 || showPlot	% Return the optimum path
	% ====== Back track to find all the other points
	dtwPath=[besti; bestj];		% The last point in the optimum path
	nextPoint=[prevPos(dtwPath(1,1), dtwPath(2,1)).i; prevPos(dtwPath(1,1), dtwPath(2,1)).j];
	while nextPoint(1)>0 & nextPoint(2)>0
		dtwPath=[nextPoint, dtwPath];
		nextPoint=[prevPos(dtwPath(1,1), dtwPath(2,1)).i; prevPos(dtwPath(1,1), dtwPath(2,1)).j];
	end
end

if nargout>3	% To return "note"
	for i=1:len2
		yPos=dtwPath(2,:);
		note(i).pvIndex=find(yPos==i);
		thePv=vec1(note(i).pvIndex);
		[~, index]=min(sum(abs(repmat(thePv, 1, stdScaleCount)-repmat(stdScale, length(thePv), 1)), 1));
        
        M = max(thePv);
        m = 300000;
        id = 0;
        len = size(stdScale);
         for j = 1:len(1,2)
            dis = stdScale(j)-M;
            
            if(dis < 0)
                dis = -dis;
            end
            if(m > dis)
                m = dis;
                id = j;
            end
         end
        
        disp(size(flux));
        if(mean(flux) > 0.0168)
            disp("true")
            note(i).pitch=stdScale(id);
        else
            disp("false")
            note(i).pitch=stdScale(index);
        end
        
		note(i).duration=length(note(i).pvIndex)/opt.frameRate;
		note(i).meanPitchError=mean(abs(vec1(note(i).pvIndex)-note(i).pitch));
	end
end

% ====== Plotting if necessary
if showPlot, dtwPathPlot(vec1, vec2, dtwPath, 'auto', minDist); end

% Min distance of pv to a note
function distance=pv2noteDist(pv, stdScale)	% pv is a col vec, stdScale is a row vec
stdScaleCount=length(stdScale);
pvCount=length(pv);
distance=min(sum(abs(repmat(pv, 1, stdScaleCount)-repmat(stdScale, pvCount, 1)), 1));

% ====== Self demo
function selfdemo
mObj=mFileParse(which(mfilename));
strEval(mObj.example);
