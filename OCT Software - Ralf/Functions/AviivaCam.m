% Ralf Mouthaan
% University of Adelaide
% August 2024
% 
% Class for controlling Aviivacam from Matlab. Relies on
% AviivaCam.dll and AviivaCam.h, which were written to replace Mingzhou's
% code which no longer works. Written for Freja Hoier.

classdef AviivaCam

    properties
        locExposure = 0; % A local estimate of what the exposure is.
        bolStartup = false;
        bolStreaming = false;
    end

    methods

        function obj = AviivaCam() 

            % Load DLL
            if libisloaded('AviivaCamDll') == false
                loadlibrary('AviivaCamDll', 'AviivaCamDll.h');
            end
            
        end
        function delete(~)

            if libisloaded('AviivaCamDll') == true
                unloadlibrary('AviivaCam');
            end

        end

        function me = Startup(me)

            fprintf('Aviiva Cam: Starting up...\n')

            % Call startup
            Err = calllib('AviivaCamDll', 'Startup');
            switch Err
                case -1
                    error('Could not find camera. Is camera connected, and is MAC address correct?');
                case -2
                    error('Unable to connect to camera');
                case -3
                    error('Cannot stream from camera');
                case -4
                    error('Camera does not support GEV');
            end

            me.bolStartup = true;
            me.locExposure = me.GetExposure();

        end
        function me = Shutdown(me)
            
            fprintf('Aviiva Cam: Shutting Down...\n')
            
            if me.bolStartup == false
                return;
            end

            calllib('AviivaCamDll', 'Shutdown');
            me.bolStartup = false;

        end
        
        function me = StartStreaming(me)

            fprintf('Aviiva Cam: Starting streaming...\n')

            % Check we're not already streaming
            if me.bolStreaming == true
                return;
            end

            % Check camera is on.
            if me.bolStartup == false
                error('Start camera before you start streaming');
            end

            calllib('AviivaCamDll', 'StartStreaming');

            me.bolStreaming = true;
            
            me.GetImage();
            me.waitfor(me.locExposure);
            me.GetImage();

        end
        function me = StopStreaming(me)

            fprintf('Aviiva Cam: Stopping Streaming\n')

            if me.bolStartup == false
                error('Camera has not been started');
            end
            if me.bolStreaming == true
                calllib('AviivaCamDll', 'StopStreaming');
                me.bolStreaming = false;
            end

        end
        
        function Image = GetImage(me)

            if me.bolStartup == false
                error('Camera has not been started');
            end
            if me.bolStreaming == false
                error('Camera is not streaming');
            end

            Width = me.GetWidth();
            Height = me.GetHeight();
            Image = zeros(Width, Height);

%             me.waitfor(me.locExposure*1.2);
%             [Err, Image] = calllib('AviivaCamDll', 'GetImage', Image);
% 
%             if Err < 0
%                 error('Failed to acquire image');
%             end

            % This is a hack to ensure we get an up to date image. I should
            % check the C++ code on all this.
            
            % Flush image buffer
            Err = 0;
            count = 0;
            while Err == 0

                count = count + 1;
                if count > 10
                    break;
                end

                [Err, Image] = calllib('AviivaCamDll', 'GetImage', Image);

            end

            % Acquire new image
            count = 0;
            while Err < 0

                count = count + 1;
                if count > 10
                    error('Failed to acquire image abc');
                end

                me.waitfor(me.locExposure);
                [Err, Image] = calllib('AviivaCamDll', 'GetImage', Image);

            end

            Image = Image.'; % We seem to need to flip it.

        end
        
        function Width = GetWidth(me)

            if me.bolStartup == false
                error('Camera has not been started')
            end

            Width = 0;
            [Err, Width] = calllib('AviivaCamDll', 'GetWidth', Width);

            if Err ~= 0
                error('Could not determine image width');
            end
            if Width == 0
                error('Could not determine image width')
            end

        end
        function Height = GetHeight(me)

            if me.bolStartup == false
                error('Camera has not been started')
            end

            Height = 0;
            [Err, Height] = calllib('AviivaCamDll', 'GetHeight', Height);

            if Err ~= 0
                error('Could not determine image height');
            end
            if Height == 0
                error('Could not determine image height')
            end

        end
        function Gain = GetGain(me)

            if me.bolStartup == false
                error('Camera has not been started');
            end

            Gain = 0.0;
            [Err, Gain] = calllib('AviivaCamDll', 'GetGain', Gain);

            if Err ~= 0
                error('Could not determine camera gain');
            end

        end
        function SetGain(me, Gain)

            if me.bolStartup == false
                error('Camera has not been started');
            end
            if me.bolStreaming == true
                error('Cannot change gain while camera is streaming');
            end

            Err = calllib('AviivaCamDll', 'SetGain', Gain);

            if Err ~= 0
                error('Could not set gain');
            end

        end
        function Exposure = GetExposure(me)
    
            if me.bolStartup == false
                error('Camera has not been started')
            end

            Exposure = 0.0;
            [Err, Exposure] = calllib('AviivaCamDll', 'GetExposure', Exposure);

            if Err ~= 0
                error('Could not determine camera exposure');
            end

            me.locExposure = Exposure;

        end
        function me = SetExposure(me, Exposure)

           if me.bolStartup == false
                error('Camera has not been started');
            end
            if me.bolStreaming == true
                error('Cannot change exposure while camera is streaming');
            end

            Err = calllib('AviivaCamDll', 'SetExposure', Exposure);

            if Err ~= 0
                error('Could not set exposure');
            end

            me.locExposure = Exposure;

        end

        function waitfor(me, waitformilliseconds)

            % I have a strong suspiction the pause() function doesn't allow
            % the C++ dll to run in the background, so instead we do this.
            
            start = datetime('now');
            stop = datetime('now');

            while milliseconds(stop - start) < waitformilliseconds
                stop = datetime('now');
            end

        end

    end
end