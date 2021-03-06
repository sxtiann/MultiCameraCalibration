function [Err_s,Err_f,extr_cur,wand_dis,x_cur,time]=Opt_S(weight,im_coordinate,extr_cur,P_point,focal_len,x_cur,M,N_fp,N,marker_dis,itr_max,th)
%%%%%%%%%%%%%%%%%%%%%% Static Calibration Trial Run %%%%%%%%%%%%%%%%%%%%%%%
% Trial run to see which set of static parameters should be used

% -------------------------------------------------------------------------
% Very important notes :
% 1) Translation should be given in the world coordinates
% -------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Authors: M. Aghamohamadian-Sharbaf, H.R. Pourreza 10/6/2014
%--------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Definition %%%%%%%%%%%%%%%%%%%%%%%%%%%%
big_iteration=0;               % Big iteration counter
delta_X=1e10;
Ea=zeros(1,4);           % This matrix contains the projection error for each point of the image (Total of four points per image for 2 marker wand)
temp1=zeros(9);

extr_cur1=extr_cur;
x_cur1=x_cur;

for n=1:N
    extr_cur(n,4:6)=-(Rotate3(extr_cur(n,1),extr_cur(n,2),extr_cur(n,3))*extr_cur(n,4:6)')'; % The traslation parameter of each camera is transformed into its own coordinate system;
end


%%%%%%%%%%%%%%%%%%%%%%% Dynamic Optimization Loop %%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial value of E
Err=0;
for m=1:M
    for n=1:N
        temp(1)=P_point(1,n) + (focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
        temp(2)=P_point(2,n) + (focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
        temp(3)=P_point(1,n) + (focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
        temp(4)=P_point(2,n) + (focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
        Err=Err+weight(m,n)*((temp(1)-im_coordinate(1,1,m,n))^2+(temp(2)-im_coordinate(1,2,m,n))^2+(temp(3)-im_coordinate(2,1,m,n))^2+(temp(4)-im_coordinate(2,2,m,n))^2);
    end
end
mu=Err;
Err_s=Err;
P1=Err;
tic
while (big_iteration<itr_max && max(abs(delta_X))>th)
    big_iteration=big_iteration+1;
    %%%%%%%%%%%%%%%%% Rotation angle estimation %%%%%%%%%%%%%%%%%%
    for n=1:N % For each camera do the following
    %%%%%%%%%%%%%%%%%%%%%%%%% Optimizatio loop %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%% Coefficient and known vector Calculation %%%%%%%%%
        Ha=zeros(3,3);     % Denotes J'*J matrix
        J_df=zeros(3,1);  % Denotes the J'*delta(f) vector
        
        m=1;
        while (m<=M)
            % values of the of the objective function
            Ea(1,1)=focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - (im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            Ea(1,2)=focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))) - (im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            Ea(1,3)=focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - (im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            Ea(1,4)=focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))) - (im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));

            % U_(2m-1,n) function
            J(1,1)=(x_cur(2*m-1,2)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,2))*sin(extr_cur(n,1)))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*(x_cur(2*m-1,2)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - x_cur(2*m-1,3)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))));
            J(1,2)=- (im_coordinate(1,1,m,n) - P_point(1,n))*(x_cur(2*m-1,1)*cos(extr_cur(n,2)) - x_cur(2*m-1,3)*cos(extr_cur(n,1))*sin(extr_cur(n,2)) + x_cur(2*m-1,2)*sin(extr_cur(n,1))*sin(extr_cur(n,2))) - focal_len(1,n)*(x_cur(2*m-1,1)*cos(extr_cur(n,3))*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2))*cos(extr_cur(n,3)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*cos(extr_cur(n,3))*sin(extr_cur(n,1)));
            J(1,3)=focal_len(1,n)*(x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
            
            Ha=Ha+weight(m,n)*(J'*J); % Addition to current hessian matrix
            J_df=J_df-weight(m,n)*[J(1,1); J(1,2); J(1,3)]*Ea(1,1); % Addition to current J'*delta(f) vector
            
            % V_(2m-1,n) function
            J(1,1)=(x_cur(2*m-1,2)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,2))*sin(extr_cur(n,1)))*(im_coordinate(1,2,m,n) - P_point(2,n)) - focal_len(2,n)*(x_cur(2*m-1,2)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,3)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))));
            J(1,2)=focal_len(2,n)*(x_cur(2*m-1,1)*sin(extr_cur(n,2))*sin(extr_cur(n,3)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2))*sin(extr_cur(n,3)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))*sin(extr_cur(n,3))) - (im_coordinate(1,2,m,n) - P_point(2,n))*(x_cur(2*m-1,1)*cos(extr_cur(n,2)) - x_cur(2*m-1,3)*cos(extr_cur(n,1))*sin(extr_cur(n,2)) + x_cur(2*m-1,2)*sin(extr_cur(n,1))*sin(extr_cur(n,2)));
            J(1,3)=-focal_len(2,n)*(x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)));
            
            Ha=Ha+weight(m,n)*(J'*J);
            J_df=J_df-[J(1,1); J(1,2); J(1,3)]*Ea(1,2)*weight(m,n);
            
            % U_(2m,n) function
            J(1,1)=(x_cur(2*m,2)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,2))*sin(extr_cur(n,1)))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*(x_cur(2*m,2)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - x_cur(2*m,3)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))));
            J(1,2)=- (im_coordinate(2,1,m,n) - P_point(1,n))*(x_cur(2*m,1)*cos(extr_cur(n,2)) - x_cur(2*m,3)*cos(extr_cur(n,1))*sin(extr_cur(n,2)) + x_cur(2*m,2)*sin(extr_cur(n,1))*sin(extr_cur(n,2))) - focal_len(1,n)*(x_cur(2*m,1)*cos(extr_cur(n,3))*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2))*cos(extr_cur(n,3)) - x_cur(2*m,2)*cos(extr_cur(n,2))*cos(extr_cur(n,3))*sin(extr_cur(n,1)));
            J(1,3)=focal_len(1,n)*(x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
            
            Ha=Ha+weight(m,n)*(J'*J);
            J_df=J_df-weight(m,n)*[J(1,1); J(1,2); J(1,3)]*Ea(1,3);
            
            % V_(2m,n) function
            J(1,1)=(x_cur(2*m,2)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,2))*sin(extr_cur(n,1)))*(im_coordinate(2,2,m,n) - P_point(2,n)) - focal_len(2,n)*(x_cur(2*m,2)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,3)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))));
            J(1,2)=focal_len(2,n)*(x_cur(2*m,1)*sin(extr_cur(n,2))*sin(extr_cur(n,3)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2))*sin(extr_cur(n,3)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))*sin(extr_cur(n,3))) - (im_coordinate(2,2,m,n) - P_point(2,n))*(x_cur(2*m,1)*cos(extr_cur(n,2)) - x_cur(2*m,3)*cos(extr_cur(n,1))*sin(extr_cur(n,2)) + x_cur(2*m,2)*sin(extr_cur(n,1))*sin(extr_cur(n,2)));
            J(1,3)=-focal_len(2,n)*(x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)));

            Ha=Ha+weight(m,n)*(J'*J);
            J_df=J_df-weight(m,n)*[J(1,1); J(1,2); J(1,3)]*Ea(1,4);
            m=m+1;
        end
        %%%%%%%%%%% Addition of update to the current values %%%%%%%%%%
        extr_cur(n,1:3)=extr_cur(n,1:3)+(Ha\J_df)';
    end

    %%% 3D Coordinates and translation parameters estimation %%%%%
    % Update calculation
    Gradient=zeros(6*M+3*N,1);
    Hessian=zeros(6*M+3*N);
    for m=1:M
        for n=1:N
           % Gradient of the objective function for the m^th image of the n^th camera
           Gradient(1+(n-1)*3,1)=Gradient(1+(n-1)*3,1)+weight(m,n)*(- 2*focal_len(1,n)*((im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) - 2*focal_len(1,n)*((im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))));
           Gradient(2+(n-1)*3,1)=Gradient(2+(n-1)*3,1)+weight(m,n)*(- 2*focal_len(2,n)*((im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))) - 2*focal_len(2,n)*((im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           Gradient(3+(n-1)*3,1)=Gradient(3+(n-1)*3,1)+weight(m,n)*(2*(im_coordinate(1,1,m,n) - P_point(1,n))*((im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) + 2*(im_coordinate(2,1,m,n) - P_point(1,n))*((im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) + 2*(im_coordinate(1,2,m,n) - P_point(2,n))*((im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))) + 2*(im_coordinate(2,2,m,n) - P_point(2,n))*((im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           Gradient(3*N+1+(m-1)*6,1)=Gradient(3*N+1+(m-1)*6,1)+weight(m,n)*(2*((im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) + 2*((im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3))));
           Gradient(3*N+2+(m-1)*6,1)=Gradient(3*N+2+(m-1)*6,1)+weight(m,n)*(- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n)))*((im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)))*((im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           Gradient(3*N+3+(m-1)*6,1)=Gradient(3*N+3+(m-1)*6,1)+weight(m,n)*(- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)))*((im_coordinate(1,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)))*((im_coordinate(1,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           Gradient(3*N+4+(m-1)*6,1)=Gradient(3*N+4+(m-1)*6,1)+weight(m,n)*(2*((im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) + 2*((im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3))));
           Gradient(3*N+5+(m-1)*6,1)=Gradient(3*N+5+(m-1)*6,1)+weight(m,n)*(- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n)))*((im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)))*((im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           Gradient(3*N+6+(m-1)*6,1)=Gradient(3*N+6+(m-1)*6,1)+weight(m,n)*(- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)))*((im_coordinate(2,1,m,n) - P_point(1,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)))*((im_coordinate(2,2,m,n) - P_point(2,n))*(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1))) - focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))));
           
           % Hessian of the objective function for the m^th image of the n^th camera
           temp1(1,1)=4*focal_len(1,n)^2;
           temp1(1,3)=- 2*focal_len(1,n)*(im_coordinate(1,1,m,n) - P_point(1,n)) - 2*focal_len(1,n)*(im_coordinate(2,1,m,n) - P_point(1,n));
           temp1(1,4)=-2*focal_len(1,n)*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3)));
           temp1(1,5)=2*focal_len(1,n)*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n)));
           temp1(1,6)=2*focal_len(1,n)*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)));
           temp1(1,7)=-2*focal_len(1,n)*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3)));
           temp1(1,8)=2*focal_len(1,n)*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n)));
           temp1(1,9)=2*focal_len(1,n)*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)));
           
           temp1(2,2)=4*focal_len(2,n)^2;
           temp1(2,3)=- 2*focal_len(2,n)*(im_coordinate(1,2,m,n) - P_point(2,n)) - 2*focal_len(2,n)*(im_coordinate(2,2,m,n) - P_point(2,n));
           temp1(2,4)=-2*focal_len(2,n)*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(2,5)=2*focal_len(2,n)*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)));
           temp1(2,6)=2*focal_len(2,n)*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)));
           temp1(2,7)=-2*focal_len(2,n)*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(2,8)=2*focal_len(2,n)*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)));
           temp1(2,9)=2*focal_len(2,n)*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)));
           
           temp1(3,1)=temp1(1,3);
           temp1(3,2)=temp1(2,3);
           temp1(3,3)=2*(im_coordinate(1,1,m,n) - P_point(1,n))^2 + 2*(im_coordinate(2,1,m,n) - P_point(1,n))^2 + 2*(im_coordinate(1,2,m,n) - P_point(2,n))^2 + 2*(im_coordinate(2,2,m,n) - P_point(2,n))^2;
           temp1(3,4)=2*(im_coordinate(1,1,m,n) - P_point(1,n))*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) + 2*(im_coordinate(1,2,m,n) - P_point(2,n))*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(3,5)=- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n)))*(im_coordinate(1,1,m,n) - P_point(1,n)) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)))*(im_coordinate(1,2,m,n) - P_point(2,n));
           temp1(3,6)=- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)))*(im_coordinate(1,1,m,n) - P_point(1,n)) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)))*(im_coordinate(1,2,m,n) - P_point(2,n));
           temp1(3,7)=2*(im_coordinate(2,1,m,n) - P_point(1,n))*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) + 2*(im_coordinate(2,2,m,n) - P_point(2,n))*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(3,8)=- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n)))*(im_coordinate(2,1,m,n) - P_point(1,n)) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)))*(im_coordinate(2,2,m,n) - P_point(2,n));
           temp1(3,9)=- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)))*(im_coordinate(2,1,m,n) - P_point(1,n)) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)))*(im_coordinate(2,2,m,n) - P_point(2,n));
           
           temp1(4,1)=temp1(1,4);
           temp1(4,2)=temp1(2,4);
           temp1(4,3)=temp1(3,4);
           temp1(4,4)=2*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))^2 + 2*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))^2;
           temp1(4,5)=- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n)))*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)))*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(4,6)=- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)))*(sin(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)))*(sin(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           
           temp1(5,1)=temp1(1,5);
           temp1(5,2)=temp1(2,5);
           temp1(5,3)=temp1(3,5);
           temp1(5,4)=temp1(4,5);
           temp1(5,5)=2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n)))^2 + 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)))^2;
           temp1(5,6)=2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)))*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,1,m,n) - P_point(1,n))) + 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)))*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(1,2,m,n) - P_point(2,n)));
           
           temp1(6,1)=temp1(1,6);
           temp1(6,2)=temp1(2,6);
           temp1(6,3)=temp1(3,6);
           temp1(6,4)=temp1(4,6);
           temp1(6,5)=temp1(5,6);
           temp1(6,6)=2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,1,m,n) - P_point(1,n)))^2 + 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(1,2,m,n) - P_point(2,n)))^2;
           
           temp1(7,1)=temp1(1,7);
           temp1(7,2)=temp1(2,7);
           temp1(7,3)=temp1(3,7);
           temp1(7,7)=2*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3)))^2 + 2*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)))^2;
           temp1(7,8)=- 2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n)))*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)))*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           temp1(7,9)=- 2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)))*(sin(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)) - focal_len(1,n)*cos(extr_cur(n,2))*cos(extr_cur(n,3))) - 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)))*(sin(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)) + focal_len(2,n)*cos(extr_cur(n,2))*sin(extr_cur(n,3)));
           
           temp1(8,1)=temp1(1,8);
           temp1(8,2)=temp1(2,8);
           temp1(8,3)=temp1(3,8);
           temp1(8,7)=temp1(7,8);
           temp1(8,8)=2*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n)))^2 + 2*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)))^2;
           temp1(8,9)=2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)))*(focal_len(1,n)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,1,m,n) - P_point(1,n))) + 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)))*(focal_len(2,n)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + cos(extr_cur(n,2))*sin(extr_cur(n,1))*(im_coordinate(2,2,m,n) - P_point(2,n)));
           
           temp1(9,1)=temp1(1,9);
           temp1(9,2)=temp1(2,9);
           temp1(9,3)=temp1(3,9);
           temp1(9,7)=temp1(7,9);
           temp1(9,8)=temp1(8,9);
           temp1(9,9)=2*(focal_len(1,n)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,1,m,n) - P_point(1,n)))^2 + 2*(focal_len(2,n)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - cos(extr_cur(n,1))*cos(extr_cur(n,2))*(im_coordinate(2,2,m,n) - P_point(2,n)))^2;
           
           Hessian(1+(n-1)*3:n*3,1+(n-1)*3:n*3)=Hessian(1+(n-1)*3:n*3,1+(n-1)*3:n*3)+weight(m,n)*temp1(1:3,1:3);
           Hessian(3*N+1+(m-1)*6:3*N+m*6,3*N+1+(m-1)*6:3*N+m*6)=Hessian(3*N+1+(m-1)*6:3*N+m*6,3*N+1+(m-1)*6:3*N+m*6)+weight(m,n)*temp1(4:9,4:9);
           Hessian(1+(n-1)*3:n*3,3*N+1+(m-1)*6:3*N+m*6)=Hessian(1+(n-1)*3:n*3,3*N+1+(m-1)*6:3*N+m*6)+weight(m,n)*temp1(1:3,4:9);
           Hessian(3*N+1+(m-1)*6:3*N+m*6,1+(n-1)*3:n*3)=Hessian(3*N+1+(m-1)*6:3*N+m*6,1+(n-1)*3:n*3)+weight(m,n)*temp1(4:9,1:3);
       end
    end
    delta_X=(Hessian+mu*eye(6*M+3*N))\(-Gradient); % Update vector calculation

    % Addition of updates to the current values
    for n=1:N
        extr_cur(n,4:6)=extr_cur(n,4:6)+delta_X(3*(n-1)+1:3*n)';
    end
    for m=1:M
        x_cur(2*m-1,:)=x_cur(2*m-1,:)+delta_X(3*N+6*(m-1)+1:3*N+6*(m-1)+3)';
        x_cur(2*m,:)=x_cur(2*m,:)+delta_X(3*N+6*(m-1)+4:3*N+6*(m-1)+6)';
    end
    
    %%%%%%%%%%% Projection error at each iteration %%%%%%%%%%%%%%%
    Err_f =0;
    for m=1:M
        for n=1:N
            temp(1)=P_point(1,n) + (focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m-1,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m-1,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            temp(2)=P_point(2,n) + (focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m-1,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m-1,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m-1,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m-1,1)*sin(extr_cur(n,2)) + x_cur(2*m-1,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m-1,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            temp(3)=P_point(1,n) + (focal_len(1,n)*(extr_cur(n,4) + x_cur(2*m,2)*(cos(extr_cur(n,1))*sin(extr_cur(n,3)) + cos(extr_cur(n,3))*sin(extr_cur(n,1))*sin(extr_cur(n,2))) + x_cur(2*m,3)*(sin(extr_cur(n,1))*sin(extr_cur(n,3)) - cos(extr_cur(n,1))*cos(extr_cur(n,3))*sin(extr_cur(n,2))) + x_cur(2*m,1)*cos(extr_cur(n,2))*cos(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            temp(4)=P_point(2,n) + (focal_len(2,n)*(extr_cur(n,5) + x_cur(2*m,2)*(cos(extr_cur(n,1))*cos(extr_cur(n,3)) - sin(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) + x_cur(2*m,3)*(cos(extr_cur(n,3))*sin(extr_cur(n,1)) + cos(extr_cur(n,1))*sin(extr_cur(n,2))*sin(extr_cur(n,3))) - x_cur(2*m,1)*cos(extr_cur(n,2))*sin(extr_cur(n,3))))/(extr_cur(n,6) + x_cur(2*m,1)*sin(extr_cur(n,2)) + x_cur(2*m,3)*cos(extr_cur(n,1))*cos(extr_cur(n,2)) - x_cur(2*m,2)*cos(extr_cur(n,2))*sin(extr_cur(n,1)));
            Err_f=Err_f+weight(m,n)*((temp(1)-im_coordinate(1,1,m,n))^2+(temp(2)-im_coordinate(1,2,m,n))^2+(temp(3)-im_coordinate(2,1,m,n))^2+(temp(4)-im_coordinate(2,2,m,n))^2);
        end
    end
    if (P1<Err_f)
        mu=2*mu;
        extr_cur=extr_cur1;
        x_cur=x_cur1;    
    elseif (P1>=Err_f)
        mu=0.5*mu;
        extr_cur1=extr_cur;
        x_cur1=x_cur;
        P1=Err_f
    end
end
time=toc;
Err_f=P1;
wand_dis=sqrt(sum(((x_cur(1:2:2*M,:)-x_cur(2:2:2*M,:)).^2)')'); % Marker distance for each set of 3D points.

for n=1:N
    extr_cur(n,4:6)=-((Rotate3(extr_cur(n,1),extr_cur(n,2),extr_cur(n,3)))'*extr_cur(n,4:6)')'; % The traslation parameter of each camera in the world coordinate system
end
end