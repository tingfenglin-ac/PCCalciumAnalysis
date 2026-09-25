function [corrF]=FBackCorr(F,hz)
if length(size(F))==2
    pcr=prctile(F,20,1);
    corrF=(F-repmat(pcr,size(F,1),1))./pcr;
end
if length(size(F))==3
    pcr=prctile(F,20,3);
    corrF=(F-pcr)./pcr;
end


