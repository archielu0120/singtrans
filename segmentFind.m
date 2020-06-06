function segment=segmentFind(inputVec, opt, showPlot)
% segmentFind: find positive segment in a vector
%	Usage:
%		segment=segmentFind(inputVec)
%
%	Example:
%		x=randsrc(1, 20);
%		x(x==-1)=0;
%		segment=segmentFind(x, [], 1);
%		fprintf('x = %s\n', mat2str(x));
%		for i=1:length(segment)
%			fprintf('Segment %d: %d~%d\n', i, segment(i).begin, segment(i).end);
%		end

%	Category: Segment processing
%	Roger Jang, 20041021, 20190206

if nargin<1, selfdemo; return; end
if ischar(inputVec) && strcmpi(inputVec, 'defaultOpt')	% Set the default options
	segment.maxGap=inf;
	return
end
if nargin<2||isempty(opt), opt=feval(mfilename, 'defaultOpt'); end
if nargin<3, showPlot=0; end

segment=[];
pitch = inputVec;
inputVec=inputVec(:)';
inputVec=inputVec>0;
start=find(diff([0, inputVec, 0])==1);
stop= find(diff([0, inputVec, 0])==-1)-1;
segmentNum=length(start);
for i=1:segmentNum
    dis = pitch(start(i))-pitch(stop(i));
    if(dis < 0)
        dis = -dis;
    end
    mid = round((-start(i)+stop(i))/2);
    if(dis > 1)
         start = [start(1:i), start(i) + mid, start(i+1:segmentNum)];
         stop = [stop(1:i-1), start(i) + mid, stop(i) ,stop(i+1:segmentNum)];
         segmentNum = segmentNum + 1;
    end
end

disp(segmentNum)
for i=1:segmentNum
	segment(i).begin=start(i);
	segment(i).end=stop(i);
	segment(i).duration=stop(i)-start(i)+1;
end
if showPlot
	plot(inputVec, '.-');
	margin=(max(inputVec)-min(inputVec))*0.5;
	set(gca, 'ylim', [min(inputVec)-margin, max(inputVec)+margin]);
	axisLimit=axis;
	for i=1:length(segment)
		line((segment(i).begin-0.5)*[1 1], axisLimit(3:4), 'color', 'g');
		line((segment(i).end+0.5)*[1 1], axisLimit(3:4), 'color', 'm');
	end
end

% ====== Self demo
function selfdemo
mObj=mFileParse(which(mfilename));
strEval(mObj.example);