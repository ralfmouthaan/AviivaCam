// Ralf Mouthaan
// University of Adelaide
// July 2024
// 
// Development of code for Aviiva camera
// Starting out with a script, but ultimate aim is to have a DLL that can be called
// from .NET or Matlab.
//
// Note, the WIN32 preprocessor flag needs to be set, even when running in 64 bits.
// Visual Studio needs to be restarted after setting up header and library folders.

#include <iostream>
#include <list>

#include <PvSampleUtils.h>
#include <PvDevice.h>
#include <PvDeviceGEV.h>
#include <PvDeviceU3V.h>
#include <PvStream.h>
#include <PvStreamGEV.h>
#include <PvStreamU3V.h>
#include <PvBuffer.h>

#include <opencv2/opencv.hpp>
#include <opencv2/core/utils/logger.hpp>

#include "AviivaCam.h"

int main() {

    uint8_t* pImg;
    cv::Mat MatImg;
    int64_t Width, Height = 0;

    // Startup camera
    cout << "Starting up camera... \n";
    Aviiva::Startup();

    double Exposure;
    int Err = Aviiva::GetExposure2(&Exposure);

    cout << Exposure;

    // Determine camera size
    // Pre-allocate image array
    Aviiva::GetWidth(Width);
    Aviiva::GetHeight(Height);
    pImg = (uint8_t*)malloc(Height * Width);

    // Stream
    cout << "Streaming...\n";
    Aviiva::StartStreaming();
    for (int i = 0; i < 100; i++) {
        cout << i << '\n';
        Aviiva::GetImage(pImg);
        MatImg = cv::Mat(Height, Width, CV_8UC1, pImg);
        cv::imshow("", MatImg);
        cv::waitKey(100);
    }

    cout << "Shutting down...\n";
    Aviiva::StopStreaming();
    Aviiva::Shutdown();

}