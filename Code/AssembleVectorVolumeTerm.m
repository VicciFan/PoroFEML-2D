function [F]=AssembleVectorVolumeTerm(meshObj,Geometry,Operator,ValueList,ID_array,IntegrationOrder)

% ValueList
% either
% [dof node1 intensity1 node2   intensity2 ] -- we assume therefore that the Load varies as the element order
% we assume that we have adjacent nodes (node1 node2)... (such that we get it define an element edge)..

nnodes=meshObj.n_nodes;

switch Operator
    
    case 'InitialStress'  % elastic boundary loads.
        ndof = 2; % number of dof per nodes
        tot_dof = length(ID_array(:));
        n_row=tot_dof;
     
        if (n_row~=nnodes*ndof)
            disp('error in id_array given');
            return;
        end
        
        [nr , ncv]=size(ValueList);
        disp(  [nr , ncv]);
        if ( (nr~=1) && (nr~=meshObj.Nelts))
            disp('error in number of rows in given stress field ');
            return;
        end
        
        switch Geometry
            case 'Axis'
                if ncv~=4
                    disp('Error - stress given does not have 4 components');
                    return;
                end
                
            case '2D'
                if ncv~=3
                    disp('Error - stress given does not have 4 components');
                    return;
                end
        end
        %         if (ncv ~=5)
        %             disp('Error in boundary value input');
        %             abort()
        %         end
        
end

S0=ValueList(1,:);

F=sparse(n_row,1);

for e=1:meshObj.Nelts
    
    kt=find(meshObj.conn(e,:)~=-1);
    local_ien= meshObj.conn(e,kt);
    
    neq_row=[];
    for i=1:length(local_ien)
        neq_row=[neq_row ID_array(local_ien(i),:)];
    end
    
    
    mycoor=meshObj.XY(local_ien,:);
    
    switch meshObj.EltType{e}
        case 'Seg'
            
            local_elt=Element_Seg2(Geometry,mycoor,local_ien); %,e
            
        case 'Qua'
            
            local_elt=Element_Qua4(Geometry,mycoor,local_ien);
            
        case 'Tri'
            %
            local_elt=Element_Tri3(Geometry,mycoor,local_ien);
      
            
    end
    
    if (nr~=1)
            S0= ValueList(e,:)';
    end
        
    
    switch Operator
        
        case 'InitialStress'
            tt=Operator_Load_InitialStress(local_elt,S0);
            
    end
    
    % element matrix integration
    elt_F=@(xi) K_Elt_Int(xi,tt); % create function handle
   
    [Kel]=GaussIntegration(elt_F,2,IntegrationOrder);
    
    %  [nr nc]=size(Kel);
    
    %      disp([nr nc]);
    %      disp([length(neq_row) length(neq_col)]);
    
    
    F(neq_row,1)=F(neq_row,1)+Kel;
    
end

end