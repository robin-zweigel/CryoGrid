%========================================================================
% Same as FORCING_slope_seb_readNC, with small adaptations to fit with
% Vegetation classes.
% R. B. Zweigel, August 2021
%========================================================================

classdef FORCING_slope_seb_readNC < FORCING_base & READ_FORCING_NC
    
    properties
        
    end
    
    
    methods
        %mandatory functions
        
        function forcing = provide_PARA(forcing)
            % INITIALIZE_PARA  Initializes PARA structure, setting the variables in PARA.
            
            forcing.PARA.forcing_path = [];
            forcing.PARA.start_time = []; % start time of the simulations (must be within the range of data in forcing file)
            forcing.PARA.end_time = [];   % end time of the simulations (must be within the range of data in forcing file)
            forcing.PARA.rain_fraction = [];  %rainfall fraction assumed in sumulations (rainfall from the forcing data file is multiplied by this parameter)
            forcing.PARA.snow_fraction = [];  %snowfall fraction assumed in sumulations (snowfall from the forcing data file is multiplied by this parameter)
            forcing.PARA.all_rain_T = [];
            forcing.PARA.all_snow_T = [];
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
            % Read forcing data
            forcing = read_NC_ERA5(forcing, tile); % Read files and populate forcing.DATA
            
            forcing = check_and_correct(forcing); % Remove known errors
            forcing = initialize_TEMP(forcing);
            forcing = initialize_TEMP_slope(forcing);
            forcing = set_start_and_end_time(forcing); % assign start/end time
            
            forcing = split_precip_Tair(forcing); % distinguish snow-/rainfall
            forcing = reduce_precip_slope(forcing, tile);
            
            forcing = split_Sin(forcing); % split Sin in dir and dif
            forcing = terrain_corr_Sin_dif(forcing);
            forcing = reproject_Sin_dir(forcing, tile);
            forcing = terrain_corr_Lin(forcing);
        end
        
        function forcing = interpolate_forcing(forcing, tile)
            forcing = interpolate_forcing@FORCING_base(forcing, tile);
            
            forcing.TEMP.rainfall = forcing.TEMP.rainfall + double(forcing.TEMP.Tair > 2) .* forcing.TEMP.snowfall;  %reassign unphysical snowfall
            forcing.TEMP.snowfall = double(forcing.TEMP.Tair <= 2) .* forcing.TEMP.snowfall;
        end
        
    end
end