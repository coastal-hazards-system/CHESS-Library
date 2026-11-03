function [Hm0, Depth_Limited_Waves] = apply_depth_limitation(Hm0, Tp, h, g)
% apply_depth_limitation  Limit wave heights to the depth-limited height.
%   [Hm0, Depth_Limited_Waves] = apply_depth_limitation(Hm0, Tp, h, g)
%
%   Depth-limited wave height Hb = K_b * 0.1 * L * tanh(k * h), with K_b = 1,
%   k the linear-theory wave number of Tp at depth h (wavnum1_VG) and
%   L = 2*pi/k. Where Hb <= 0 (no positive depth) Hb takes the Hm0 value.
%   Hm0 is replaced by Hb where Hm0 > Hb, and set to 0 where h < 0
%   (emergent toe).
%
%   Inputs:
%     Hm0 - significant wave height [m], double array
%     Tp  - peak wave period [s], double array (same size as Hm0)
%     h   - water depth at the toe [m], double array (same size as Hm0)
%     g   - gravity [m/s^2], scalar double
%   Outputs:
%     Hm0                 - depth-limited wave height [m], same size as the
%                           input
%     Depth_Limited_Waves - depth-limited wave height Hb [m], same size as
%                           Hm0
%
%   Tier: internal
%
%   See also adjust_wave_height, wavnum1_VG.

%% VECTORIZE INPUTS
data_dims = size(Hm0);
Hm0 = Hm0(:);
Tp = Tp(:);
h = h(:);

%% Depth limitation wave transformation
%     disp('      Checking for depth limited waves...')
% Empirical Breaker Index Coefficient
K_b =  1; % max(0.01,normrnd(1,0.3,size(h)));
% Compute Wave Number
[km,~,~]=cellfun(@(x,y) wavnum1_VG(x,y,g),{Tp},{h},'UniformOutput',false);
km = cell2mat(km);
% Compute Depth Limited Waves
Depth_Limited_Waves=K_b*0.1.*(2*pi./km(:,1)).*tanh(km(:,1).*h);
Depth_Limited_Waves(Depth_Limited_Waves<=0)=Hm0(Depth_Limited_Waves<=0); %negative h was making these waves negative (not realistic)
% Ratio Check
Ratio_Check = Depth_Limited_Waves./h;
% Replace Hm0 With Depth Limited Value If Hm0>Hm0_DL
Hm0(Hm0>Depth_Limited_Waves) = Depth_Limited_Waves(Hm0>Depth_Limited_Waves);
% Make sure to set to 0 instances of emergent toe (h<0)
Hm0(h<0) = 0;
% Reshape
Hm0 = reshape(Hm0,data_dims);
Depth_Limited_Waves = reshape(Depth_Limited_Waves,data_dims);

end