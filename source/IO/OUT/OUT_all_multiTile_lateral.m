%========================================================================
% CryoGrid OUT class defining storage format of the output 
% OUT_all_multiTile_lateral stores identical copies of all GROUND classses (including STATVAR, TEMP, PARA) in the
% stratigraphy for each output timestep and copies of all LATERAL classes.
% Other than that, it is identical to OUT_all. It can be used with the
% Multi-tile classes.
% The user can specify the save date and the save interval (e.g. yearly
% files), as well as the output timestep (e.g. 6 hourly). The output files
% are in Matlab (".mat") format.
% S. Westermann, T. Ingeman-Nielsen, J. Scheer, October 2020
%========================================================================


classdef OUT_all_multiTile_lateral < matlab.mixin.Copyable

    properties
		out_index
        STRATIGRAPHY
        LATERAL
        TIMESTAMP
        MISC
        TEMP
        PARA
        OUTPUT_TIME
        SAVE_TIME
		CONST
	end
    
    
    methods
		


%         function out = initialize_excel(out)
%             
%         end
        
        function out = provide_PARA(out)         
            % INITIALIZE_PARA  Initializes PARA structure.

            out.PARA.output_timestep = [];
            out.PARA.save_date = [];
            out.PARA.save_interval = [];
        end
        
        function out = provide_CONST(out)

        end
        
        function out = provide_STATVAR(out)

        end
		
	
		function out = finalize_init(out, tile)
			% FINALIZE_SETUP  Performs all additional property
            %   initializations and modifications. Checks for some (but not
            %   all) data validity.
			
			%	ARGUMENTS:
			%	forcing:	instance of FORCING class
            forcing = tile.FORCING;
			
			out.OUTPUT_TIME = forcing.PARA.start_time + out.PARA.output_timestep;
            if isempty(out.PARA.save_interval) || isnan(out.PARA.save_interval) 
                out.SAVE_TIME = forcing.PARA.end_time;
            else
                out.SAVE_TIME = min(forcing.PARA.end_time,  datenum([out.PARA.save_date num2str(str2num(datestr(forcing.PARA.start_time,'yyyy')) + out.PARA.save_interval)], 'dd.mm.yyyy'));
            end
            out.TEMP = struct();
        end
        
        %-------time integration----------------
		            
        function out = store_OUT(out, tile)
            
             t = tile.t;
             TOP = tile.TOP; 
             BOTTOM = tile.BOTTOM;
             forcing = tile.FORCING;
             run_name = tile.PARA.run_name;
             result_path = tile.PARA.result_path;
             timestep = tile.timestep;
             
            
            if t==out.OUTPUT_TIME %|| (tile.timestep <1e-12 && t>datenum(2014,4,1))
                %if id == 1
                disp([datestr(t)])
                %end
                out.TIMESTAMP=[out.TIMESTAMP t];
                
                CURRENT = TOP.NEXT;
                if isprop(CURRENT, 'CHILD') && CURRENT.CHILD ~= 0
                    out.MISC=[out.MISC [CURRENT.CHILD.STATVAR.T(1,1); CURRENT.CHILD.STATVAR.layerThick(1,1)]]; 
                else
                    out.MISC=[out.MISC [NaN; NaN]];
                end
                
                
                result = copy_and_store(out, TOP, BOTTOM);
                out.STRATIGRAPHY{1,size(out.STRATIGRAPHY,2)+1} = result;
                
                %lateral, read only STATVAR and PARA---
                result={};
                ia_classes = tile.LATERAL.IA_CLASSES;
                for i=1:size(ia_classes,1)
                    res = copy(ia_classes{i,1});
                    vars = fieldnames(res);
                    for j=1:size(vars,1)
                        if ~strcmp(vars{j,1}, 'PARA') && ~strcmp(vars{j,1}, 'STATVAR')
                           res.(vars{j,1}) = []; 
                        end
                    end
                    result=[result; {res}];                    
                end
                out.LATERAL{1,size(out.LATERAL, 2)+1} = result;
                %---
                
                out.OUTPUT_TIME = out.OUTPUT_TIME + out.PARA.output_timestep;
                if t==out.SAVE_TIME  %|| (tile.timestep <1e-12 && t>datenum(2014,4,1))
                   if ~(exist([result_path run_name])==7)
                       mkdir([result_path run_name])
                   end
                   save([result_path run_name '/' run_name '_' datestr(t,'yyyymmdd') '.mat'], 'out')
                   out.STRATIGRAPHY=[];
                   out.LATERAL=[];
                   out.TIMESTAMP=[];
                   out.MISC=[];
                   out.SAVE_TIME = min(forcing.PARA.end_time,  datenum([out.PARA.save_date num2str(str2num(datestr(out.SAVE_TIME,'yyyy')) + out.PARA.save_interval)], 'dd.mm.yyyy'));
                end
            end
        end


        function result = copy_and_store(out, TOP, BOTTOM)
            

            CURRENT = TOP.NEXT;

            result={};
            while ~isequal(CURRENT, BOTTOM)
                if isprop(CURRENT, 'CHILD') && CURRENT.CHILD ~= 0
                    res=copy(CURRENT.CHILD);
                    res.NEXT =[]; res.PREVIOUS=[]; res.IA_NEXT=[]; res.IA_NEXT=[];  res.PARENT = []; %cut all dependencies
                    result=[result; {res}];
                end
                res = copy(CURRENT);
                if isprop(res, 'LUT')
                    res.LUT =[];  %remove look-up tables, runs out of memory otherwise
                end
                if isprop(res, 'READ_OUT')
                    res.READ_OUT =[];  %remove look-up tables, runs out of memory otherwise
                end
                if isprop(res, 'STORE')
                    res.STORE = [];
                end
                res.NEXT =[]; res.PREVIOUS=[]; res.IA_NEXT=[]; res.IA_PREVIOUS=[];  %cut all dependencies
                if isprop(res, 'CHILD')
                    res.CHILD = [];
                    res.IA_CHILD =[];
                end
                if isfield(res.STATVAR, 'SUB_TILES_TOP')
                    for j=1:size(res.STATVAR.SUB_TILES_TOP,1)
                        res.STATVAR.SUB_TILES{j,1} = copy_and_store(out, res.STATVAR.SUB_TILES_TOP{j,1}, res.STATVAR.SUB_TILES_BOTTOM{j,1});
                    end
                    res.STATVAR.SUB_TILES_TOP = [];
                    res.STATVAR.SUB_TILES_BOTTOM = [];
                end
                
                result=[result; {res}];
                CURRENT = CURRENT.NEXT;
            end
            
        end
         

        
    end
end