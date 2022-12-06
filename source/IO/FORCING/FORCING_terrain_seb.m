%========================================================================
% Same as FORCING_slope_seb_readNC2_new, but getting terrain parameters 
% from file generated by TopoPAR.
% Also includes shading from surrounding terrain (as in TopoSCALE).
% R. B. Zweigel, September 2022
%========================================================================

classdef FORCING_terrain_seb < FORCING_base & READ_FORCING_mat
    
    properties
        
    end
    
    
    methods
        %mandatory functions
        
        function forcing = provide_PARA(forcing)
            % INITIALIZE_PARA  Initializes PARA structure, setting the variables in PARA.
            
            forcing.PARA.forcing_file = [];
            forcing.PARA.start_time = []; % start time of the simulations (must be within the range of data in forcing file)
            forcing.PARA.end_time = [];   % end time of the simulations (must be within the range of data in forcing file)
            forcing.PARA.rain_fraction = [];
            forcing.PARA.snow_fraction = [];
            forcing.PARA.albedo_surrounding_terrain = [];
            forcing.PARA.heatFlux_lb = [];  % heat flux at the lower boundary [W/m2] - positive values correspond to energy gain
            forcing.PARA.airT_height = [];  % height above ground at which air temperature (and wind speed!) from the forcing data are applied.
        end
        
        function forcing = provide_CONST(forcing)
            forcing.CONST.Tmfw = [];
            forcing.CONST.sigma = [];
        end
        
        function forcing = provide_STATVAR(forcing)
            
        end
        
        function forcing = finalize_init(forcing, tile)
            forcing.DATA.timeForcing = [];
            forcing.DATA.Tair = [];
            forcing.DATA.wind = [];
            forcing.DATA.Sin = [];
            forcing.DATA.Lin = [];
            forcing.DATA.p = [];
            forcing.DATA.q = [];
            forcing.DATA.snowfall = [];
            forcing.DATA.rainfall = [];
            forcing.DATA.S_TOA = [];
            
            load(forcing.PARA.forcing_file, 'FORCING');
            variables = fields(forcing.DATA);
            for i=1:size(variables,1)
                if isfield(FORCING.data, variables{i,1})
                    forcing.DATA.(variables{i,1}) = squeeze(FORCING.data.(variables{i,1}));
                end
            end
            
%             forcing.DATA = read_mat([forcing.PARA.forcing_file],fields(forcing.DATA));      % Why does read_mat not work??  
            
            forcing = check_and_correct(forcing); % Remove known errors
            forcing = initialize_TEMP(forcing);
            forcing = initialize_TEMP_slope(forcing);
            forcing = set_start_and_end_time(forcing); % assign start/end time
            
            forcing = reduce_precip_slope(forcing, tile);
            
            forcing = split_Sin(forcing); % split Sin in dir and dif
            forcing = terrain_corr_Sin_dif(forcing, tile);
            forcing = reproject_Sin_dir(forcing, tile);
            forcing = terrain_corr_Lin(forcing, tile);
            
        end
        
        function forcing = interpolate_forcing(forcing, tile)
            forcing = interpolate_forcing@FORCING_base(forcing, tile);
            forcing = terrain_shade(forcing, tile);
            
            forcing.TEMP.rainfall = forcing.TEMP.rainfall + double(forcing.TEMP.Tair > 2) .* forcing.TEMP.snowfall;  %reassign unphysical snowfall
            forcing.TEMP.snowfall = double(forcing.TEMP.Tair <= 2) .* forcing.TEMP.snowfall;
        end
        
        
    end
end