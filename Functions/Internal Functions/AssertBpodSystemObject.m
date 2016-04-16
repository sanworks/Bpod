function AssertBpodSystemObject(BpodSystem)
if isempty(isprop(BpodSystem, 'BpodPath'))
    error('You must run Bpod before using this function.');
end