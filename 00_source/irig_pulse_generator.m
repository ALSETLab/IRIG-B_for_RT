function y2 = gen_irig_PWM_symbols(mode, hr,mints, day, yr, dst,leap, sec) %#codegen

persistent y idxSymbol idxSimFrame SimFramesPerSymbol

% Constants
IRIGSymbols = 100;

SimFramesPerSymbol = 100;
NumSymbols = IRIGSymbols;


% Initialize persistent variables
% Initialize symbols vector
if isempty(y), y = zeros(NumSymbols,1); end
% Initialize counter for symbols (goes from 1 to NumSymbols)
if isempty(idxSymbol), idxSymbol = 1; end
% Initialize counter for Simulation frame. For each symbol, the number of 
% Size of each frame is 1 samples. 
if isempty(idxSimFrame), idxSimFrame = 1; end
% Initialize number of simulation frames per symbol to SimFramesPerSymbol;
if isempty(SimFramesPerSymbol), SimFramesPerSymbol = 100; end

if (idxSymbol == 1) && (idxSimFrame == 1)
    
        x = struct('yr',0,'leap',false,'utc',0,'ut1',0,'day',0,'dst',false,'dst2',false,'mints',0,'sec',0,'hr',0);
        
        x.sec    = rem(floor(sec),60); % seconds add remainder function
        x.mints  = rem((mints+floor(sec/60)),60); % minutes
        x.hr     = rem((hr+floor(sec/3600)),24);   % hours 
           
        x.day     = day;     % day of year
        x.yr      = yr;    % year
        x.dst     = logical(dst);       % Daylight Savings Time indicator
        x.leap    = logical(leap);       % Leap second   
    
      
    % Generate symbol vector:
    y  = gen_irig(x);

    % Add a couple of symbols to the frame of data, so that
    % the decoder has time to synchronize:
    % Total number of symbols = 5+60+3 = 68.
    %     y1 =  y  ;  
end

% Generate modulated tone by doing Pulse width modulation on the WWV symbols.
% Generate NumSimFramesPerSymbol number of simulink frames for each symbol. 
y2 = zeros(1,1);
if (idxSimFrame <= SimFramesPerSymbol)
    y2 = gen_tone(y(idxSymbol),idxSimFrame);
end

idxSimFrame = idxSimFrame+1;
if (idxSimFrame > SimFramesPerSymbol)
    idxSimFrame = 1;
    idxSymbol = idxSymbol+1;
    if (idxSymbol > NumSymbols)
        idxSymbol = 1;
    end
end

function s = gen_tone(x,whichSimFrame)
 
P0   =1; % logic 0
P1   =2; % logic 1
PMARK=3; % marker


cs=5.5; % output voltage amplitude
 s = zeros(1,1);
    
switch x
    case P0,
       if (whichSimFrame <= 17)
           s = cs;
       end
    case P1,
       if (whichSimFrame <= 47)
           s = cs;
       end
    case PMARK,
       if (whichSimFrame <= 77)
           s = cs;
       end
    otherwise,
end

return


% =======================

function y = gen_irig(x)


P0    = 1;
P1    = 2;
PMARK = 3;

% Preload with all P0's:
% ---------------------------------------------
y = P0*ones(100,1);

% 10-sec markers:
% ---------------------------------------------

y(10:10:end) = PMARK;


% Start-of-frame marker:
% ---------------------------------------------
y(1) = PMARK;



% Data:
% ---------------------------------------------
ybcd = bcd(x.yr-1900,2); %year
y(51:54) = fliplr(ybcd(1:4));
y(56:59) = fliplr(ybcd(5:8));

ss=bcd(x.sec,2);   %seconds
y(2:5) = fliplr(ss(1:4));
y(7:9) = fliplr(ss(6:8));

hh = floor(x.hr);  %hours
hbcd=bcd(hh,2);
mm = x.mints; %minutes
mbcd = bcd(mm,2);
y(11:14) = fliplr(mbcd(1:4));
y(16:18) = fliplr(mbcd(6:8));
y(21:24) = fliplr(hbcd(1:4));
y(26:27) = fliplr(hbcd(7:8));

ybcda = bcd(x.day,3);   %day
y(31:34) = fliplr(ybcda(1:4));
y(36:39) = fliplr(ybcda(5:8));
y(41:42) = fliplr(ybcda(11:12));

% Control Bits (refer IRIG-B code details for more information)
% http://www.irigb.com/pdf/wp-irig-200-98.pdf
% ---------------------------------------------
y(61:63) = P0;
y(64) = bit(x.dst);
y(65) =P0;
ybcdb = bcd(abs(x.ut1*10),1);
y(66:69) = fliplr(ybcdb(1:4));
y(71) =P0;
y(72:75) =P0;

% ---------------------------------------------
% y(76) is a parity bit, so for loop to evaulate the value of parity bit:
j=0; 
for i=1:75   
    if isequal(y(i),2)==1
        j=j+1;
    else
        j=j;
    end
end
if mod(j,2)==1
    y(76)=P1;
else
 y(76)=P0;
end
% ---------------------------------------------

y(77:79) =P0; % assumed very high quality time
y(78)=P1; % assumed

%seconds of the days
% ---------------------------------------------
secofday= x.sec+(60*x.mints)+(3600*x.hr);
seconds=zeros(17,1);
seconds(1:17)=sbs(secofday);
y(81:89)=seconds(1:9);
y(91:98)=seconds(10:17);

return

% =======================

function y=bcd(d,n)
P0 = 1;
P1 = 2;
s=dec2bcd(d,n);
y=P0*ones(1,length(s)); % Set P0's
%y(find(s=='1'))=P1;    % Set P1's
for si = 1:length(s)
    if (s(si) == '1')
        y(si) = P1;
    end
end
y=fliplr(y);
return

% =======================

function y=bit(x)
P0    = 1;
P1    = 2;
if x, y=P1; else y=P0; end
return

% =======================
function y=sbs(secofday)
%straight binary seconds of the day 17 digits

P0 = 1;
P1 = 2;
%coder.extrinsic('d2b');
coder.extrinsic('str2double');

s=blanks(17);

s=fliplr(d2b(secofday,17));

y=P0*ones(1,17);
for si = 1:17
    if (s(si) == '1')
        y(si) = P1;
    else 
        y(si) = P0;
    end
end
y=fliplr(y);
return

% =======================

function y=dec2bcd(d,n)
%DEC2BCD Convert decimal integer to a binary-coded-decimal (BCD) string.
%   DEC2BCD(D) returns the BCD representation of D as a string.
%   D must be a non-negative integer.
%
%   DEC2BCD(D,N) produces a BCD representation with at least
%   N decimal digits encoded.
%
%   Example
%      dec2bcd(23) returns '00100011'
%      dec2bcd(23,3) returns '000000100011'
%
%   See also d2b, BIN2DEC, DEC2HEX, DEC2BASE.

d = abs(d(:)); % Make sure d is a column vector.

digits = zeros(1,4);    
if d<2,
    numdigits=1;
else
    numdigits=ceil(log10(d));
end

if nargin>1,
	if (numel(n)~=1) || (numdigits<0),
	   error('N must be a positive scalar.');
    end
	n = round(n); % Make sure n is an integer.
else
  n = numdigits;
end

for i=numdigits-1:-1:0
  dig = floor(d*10^(-i));
  d = d - dig*(10^i);
  digits(4-i)=dig;
end

if (n == 1)
    digits1=digits(4);
    y=zeros(1,4);
elseif (n == 2)
    digits1=digits(3:4);    
    y=zeros(1,8);
elseif (n == 3) 
    digits1=digits(2:4);
    y=zeros(1,12);    
else
    digits1=digits;
    y=zeros(1,16);    
end

for i=1:length(digits1),
  if (i == 1)
    y(1:4)=d2b(digits1(i),4);
  elseif (i == 2)
    y(5:8)=d2b(digits1(i),4);
  elseif (i == 3)
    y(9:12)=d2b(digits1(i),4);
  else
    y(13:16)=d2b(digits1(i),4);
  end
end

function s=d2b(d,n)
%   d2b(D,N) produces a binary representation with at least N bits.
%   Example d2b(23) returns '10111'
l=zeros(1,n);
s1=blanks(n);
 for i=1:n
     l(i)=48;
     s1(i)=char(l(i));
 end
 l1=zeros(1,n);
 i=0;
 while d>=1
     i=i+1;
     p=rem(d,2);
     if p==0
         l1(i)=48;
         s1(i)=char(l1(i));
     else
         l1(i)=49;
         s1(i)=char(l1(i));
     end
     d=floor(d/2);
 end
 s=s1;
 return

