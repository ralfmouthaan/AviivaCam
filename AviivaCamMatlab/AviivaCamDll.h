#pragma once

#ifdef __cplusplus
extern "C" {
#endif

	__declspec(dllexport) int Startup();
	__declspec(dllexport) int Shutdown();

	__declspec(dllexport) int StartStreaming();
	__declspec(dllexport) int StopStreaming();

	__declspec(dllexport) int GetImage(int* pImage);

	__declspec(dllexport) int GetWidth(int* Width);
	__declspec(dllexport) int GetHeight(int* Height);
	__declspec(dllexport) int GetGain(double* Gain);
	__declspec(dllexport) int SetGain(double Gain);
	__declspec(dllexport) int GetExposure(double* Exposure);
	__declspec(dllexport) int SetExposure(double Exposure);

#ifdef __cplusplus
}
#endif
