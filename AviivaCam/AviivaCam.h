#pragma once

namespace Aviiva {

	int Startup();
	int Shutdown();

	int StartStreaming();
	int StopStreaming();

	int GetImage(uint8_t* pImage);

	int GetWidth(int64_t& Width);
	int GetHeight(int64_t& Height);
	int GetGain(double& Gain);
	int SetGain(double Gain);
	int GetExposure(double& Exposure);
	int SetExposure(double Exposure);

	int GetExposure2(double* Exposure);
}
