classdef READ_FORCING_mat < READ_FORCING_base
    
    properties
        
    end
    
    methods
        function forcing = read_mat(forcing, variables)    %, start_date, end_date)
            
            data = load([forcing.PARA.forcing_path forcing.PARA.filename] , 'FORCING');
   
            % Implement some cropping of data if start_date and end_date
            % are passed

            for i=1:size(variables,1)
                if isfield(data.FORCING.data, variables{i,1}) && ~strcmpi(variables{i,1}, 't_span')
                    forcing.DATA.(variables{i,1}) = data.FORCING.data.(variables{i,1});
                end
            end

            forcing.DATA.timeForcing = data.FORCING.data.t_span;

        end

    end    
    
end
