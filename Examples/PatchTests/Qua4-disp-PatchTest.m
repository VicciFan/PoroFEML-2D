% implementation of QU4 element for plane-strain elasticity

% IMPOSED STRAIN PATCH TEST (e_xx =1, e_yy=1 exy=0 )
% create a regular Qua4 grid  of 4 elements for this patch test

ne_x=2; % do not change for this patch test.
ne_y=2; % do not change for this patch test.

ne_t=ne_x*ne_y;
ymax=1.;
xmax=1.;

hx=xmax/ne_x;
hy =ymax/ne_y;

xs=linspace(0.,xmax,ne_x+1)
ys=linspace(0.,ymax,ne_y+1)

the_coor=zeros((ne_x+1)*(ne_y+1),2);
k=1;
for i=1:length(ys)
    the_coor( k:(k+length(xs)-1),1)=xs';
    the_coor(k:(k+length(xs)-1),2)=ys(i);
    
    k=k+length(ys);
    
end
% create the corresponding connectivity table
connect=zeros(ne_t,4);
e=1;
for ey=1:ne_y
    for ex=1:ne_x
       connect(e,1:4)=[ex+(ey-1)*(ne_x+1), ex+1+(ey-1)*(ne_x+1), (ex+1)+(ey)*(ne_x+1), (ex)+(ey)*(ne_x+1)];   
       e=e+1;
    end
end

% just perturb the location of the middle node
pert=0.1;
the_coor(5,:)=the_coor(5,:)+[random('norm',0.,pert) random('norm',0.,pert)]

% simple grid plot (note should work for all linear-like mesh) .... very
% naive, lots of duplicates.... should be a loop on mesh edges.
 scatter(the_coor(:,1),the_coor(:,2)); hold on;
 for e=1:ne_t
     line(the_coor(connect(e,:),1),the_coor(connect(e,:),2)); hold on;
 end

objN=FEnode(the_coor); % obj FEnode

Ien = connect;

% add a FEM On it and interpolation
mat_zones=ones(length(Ien(:,1))); %single material
myPk=1;
mesh_fem=Mesh_with_a_FEM(myPk,objN,Ien,mat_zones); % linear FE

% MATERIAL PROPERTIES
% all stiffness in MPa, 

k=4.2e3;
g=3.1e3; 

propObject=Properties_Elastic_Isotropic(k,g,1.);

% Elasticity problem  1D plane-strain axisymmetry 
% ProblemType='Elasticity';
Config='PlaneStrain';

dof_h=DOF_handle(mesh_fem,2,'Matrix');  % the dof_handle

% impose displacement .... block bottom y_dof 
kti=find(the_coor(:,2)==0.);
Imp_displacement=[ ];
for i=1:length(kti)
    Imp_displacement =[Imp_displacement; kti(i) 2 0.];
end
% block x_dof for x==0.
kti=find(the_coor(:,1)==0.);
for i=1:length(kti)
    Imp_displacement =[Imp_displacement; kti(i) 1 0.];
end

% ct x_dof for x==xmax
kti=find(the_coor(:,1)==xmax);
for i=1:length(kti)
     Imp_displacement =[Imp_displacement; kti(i) 1 xmax];
end
% ct y_dof for y==ymax
kti=find(the_coor(:,2)==ymax);
for i=1:length(kti)
     Imp_displacement =[Imp_displacement; kti(i) 2 ymax];
end

% 
Imp_displacement =[Imp_displacement; 4 2 the_coor(4,2)];
Imp_displacement =[Imp_displacement; 6 2 the_coor(6,2)];

Imp_displacement =[Imp_displacement; 2 1 the_coor(2,1)];
Imp_displacement =[Imp_displacement; 8 1 the_coor(8,1)];
 

Boundary_loads = [ ]; 
 
% no Initial stress field 
mySig_o= zeros(mesh_fem.Nelts,3); 

% create elasticity Block
obj_elas=Elasticity_Block(Config,mesh_fem,propObject,Imp_displacement,...
    Boundary_loads,mySig_o);

[K,dof_aux]=BuildStiffness(obj_elas); 

[F]=BuildBoundaryLoad(obj_elas); 

Usol=full(Solve(obj_elas)); 

[StressG,StrainG,AvgCoor]=Stress_And_Strain(obj_elas,Usol,'Gauss');
 
[Stress,Strain,AvgCoor]=Stress_And_Strain(obj_elas,Usol);

Strain

% check that displacement solution of the mid nodes is indeed equal to its
% coordinates. (100% imposed strain)
[Usol(9) Usol(10)]

the_coor(5,:)


%figure(2)
%voronoi(objN.coor(:,1),objN.coor(:,2))

