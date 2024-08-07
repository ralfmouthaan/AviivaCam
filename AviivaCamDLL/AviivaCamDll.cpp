
#include <chrono>
#include <thread>

#include <PvSampleUtils.h>
#include <PvDevice.h>
#include <PvDeviceGEV.h>
#include <PvDeviceU3V.h>
#include <PvStream.h>
#include <PvStreamGEV.h>
#include <PvStreamU3V.h>
#include <PvBuffer.h>

#include "AviivaCamDll.h"

const PvString strMACAddress = "00:18:28:28:00:84";

PvDevice* pDevice = NULL;
PvStream* pStream = NULL;
PvBuffer* pBuffer = new PvBuffer;

bool bolStartup;

int Startup() {

    PvResult Result;

    // Find camera based on MAC address
    PvSystem* pSystem = new PvSystem;
    const PvDeviceInfo* pDeviceInfo = NULL;
    Result = pSystem->FindDevice(strMACAddress, &pDeviceInfo);
    if (Result != PvResult::Code::OK) {
        std::cout << "Could not find camera. Is MAC Address correct?\n";
        return -1;
    }
    if (pDeviceInfo == NULL) {
        std::cout << "Could not find camera. Is MAC Address correct?\n";
        return -1;
    }

    // Connect to camera
    pDevice = PvDevice::CreateAndConnect(pDeviceInfo, &Result);
    if (pDevice == NULL)
    {
        cout << "Unable to connect to camera\n";
        return -2;
    }

    // Set to mono8
    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("PixelFormat");
    PvGenEnum* pParameterEnum = static_cast<PvGenEnum*> (pParameter);
    pParameterEnum->SetValue("Mono8");

    // Open stream
    pStream = PvStream::CreateAndOpen(pDeviceInfo->GetConnectionID(), &Result);
    if (Result != PvResult::Code::OK) {
        std::cout << "Could not stream from camera.\n";
        return -3;
    }
    if (pStream == NULL) {
        std::cout << "Could not stream from camera.\n";
        return -3;
    }

    // Cast camera to GEV camera
    // Cast stream to GEV stream
    // Seem to have to cast camera after setting up stream.
    PvDeviceGEV* pDeviceGEV = dynamic_cast<PvDeviceGEV*>(pDevice);
    if (pDeviceGEV == NULL) {
        cout << "Camera does not seem to support GEV\n";
        return -4;
    }
    PvStreamGEV* pStreamGEV = static_cast<PvStreamGEV*>(pStream);
    if (pStreamGEV == NULL) {
        cout << "Camera does not seem to support GEV\n";
        return -4;
    }

    // Set up stream
    pDeviceGEV->NegotiatePacketSize();
    pDeviceGEV->SetStreamDestination(pStreamGEV->GetLocalIPAddress(), pStreamGEV->GetLocalPort());

    // Allocate memory buffers
    // We only allocate one buffer because we only care about the most recent image.
    // Other images are to be dropped.
    // This means there is no need for a buffer list
    uint32_t lSize = pDevice->GetPayloadSize(); // Size of image
    pBuffer->Alloc(static_cast<uint32_t>(lSize)); // Allocate buffer
    pStream->QueueBuffer(pBuffer); // Queue buffer in stream.

    // Enable streaming
    pDevice->StreamEnable();
    return 0;

}
int Shutdown() {

    PvResult Result;

    StopStreaming();

    // Stop acquisition
    pDevice->StreamDisable();
    pStream->AbortQueuedBuffers();
    pStream->RetrieveBuffer(&pBuffer, &Result);

    // Deallocate memory buffers
    delete pBuffer;

    // Disconnect from camera
    pDevice->Disconnect();
    PvDevice::Free(pDevice);

    return 0;

}

int StartStreaming() {

    // Get device commands needed to stop and start acquisition
    PvGenParameterArray* pDeviceParams = pDevice->GetParameters();
    PvGenCommand* pCommandStart = dynamic_cast<PvGenCommand*>(pDeviceParams->Get("AcquisitionStart"));
    pCommandStart->Execute();

    // Wait for a second before taking measurements.
    // Sometimes there are some dropped frames at the beginning, which I want to avoid.
    std::this_thread::sleep_for(std::chrono::seconds(1));

    return 0;

}
int StopStreaming() {

    // Get device commands needed to stop and start acquisition
    PvGenParameterArray* pDeviceParams = pDevice->GetParameters();
    PvGenCommand* pCommandStop = dynamic_cast<PvGenCommand*>(pDeviceParams->Get("AcquisitionStop"));
    pCommandStop->Execute();

    return 0;

}

int GetImage(int* pImage) {

    PvResult Result;
    PvResult ResultOperation = PvResult::Code::OK;

    // Try three times to get image buffer
    // After the first call to this function ResultOperation returns NOT_INITIALIZED
    // The manual says it should never do this. But it does. Ignore it?
    PvBuffer* locBuffer = NULL;
    for (int i = 0; i < 3; i++) {
        Result = pStream->RetrieveBuffer(&locBuffer, &ResultOperation, 1000);
        if (Result.IsOK()) {
            break;
        }
        PvPayloadType PayloadType = locBuffer->GetPayloadType();
        if (PayloadType == PvPayloadTypeImage) {
            break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // Error checks
    if (!Result.IsOK()) {
        cout << "Failed to acquire image buffer.\n";
        return -1;
    }
    PvPayloadType PayloadType = locBuffer->GetPayloadType();
    if (PayloadType != PvPayloadTypeImage) {
        cout << "Failed to acquire image\n";
        pStream->QueueBuffer(locBuffer);
        return -2;
    }

    // Try three times to get an image
    PvImage* pImageData;
    for (int i = 0; i < 3; i++) {
        pImageData = locBuffer->GetImage();
        if (pImageData->GetWidth() != 0 && pImageData->GetHeight() != 0) {
            break;
        }
    }

    // Error checks
    if (pImageData->GetWidth() == 0 && pImageData->GetHeight() == 0) {
        cout << "Failed to acquire image\n";
        pStream->QueueBuffer(locBuffer);
        return -3;
    }

    // Get image
    for (int i = 0; i < pImageData->GetWidth() * pImageData->GetHeight(); i++) {
        pImage[i] = (pImageData->GetDataPointer())[i];
    }
    //memcpy(pImage, pImageData->GetDataPointer(), pImageData->GetWidth() * pImageData->GetHeight());

    // Re-Queue buffer
    pStream->QueueBuffer(locBuffer);
    return 0;

}

int GetWidth(int* RetVal) {

    int64_t Width;
    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("Width");
    PvGenInteger* pWidth = dynamic_cast<PvGenInteger*>(pParameter);
    if (pWidth == NULL) {
        return -1;
    }
    if (pWidth->GetValue(Width).IsOK() == false) {
        return -2;
    }

    *RetVal = (int)Width;

    return 0;

}
int GetHeight(int* RetVal) {

    int64_t Height;
    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("Height");
    PvGenInteger* pHeight = dynamic_cast<PvGenInteger*>(pParameter);
    if (pHeight == NULL) {
        return -1;
    }
    if (pHeight->GetValue(Height).IsOK() == false) {
        return -2;
    }

    *RetVal = (int)Height;
    return 0;

}
int GetGain(double* RetVal) {

    double Gain;
    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("Gain");
    PvGenFloat* pGain = dynamic_cast<PvGenFloat*>(pParameter);
    if (pGain == NULL) {
        return -1;
    }
    if (pGain->GetValue(Gain).IsOK() == false) {
        return -2;
    }

    *RetVal = Gain;

    return 0;

}
int SetGain(double Gain) {

    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("Gain");
    PvGenFloat* pGain = dynamic_cast<PvGenFloat*>(pParameter);
    if (pGain == NULL) {
        return -1;
    }
    if (pGain->SetValue(Gain).IsOK() == false) {
        return -2;
    }

    return 0;

}
int GetExposure(double* RetVal) {

    double Exposure;
    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("ExposureTime");
    PvGenFloat* pExposure = dynamic_cast<PvGenFloat*>(pParameter);
    if (pExposure == NULL) {
        return -1;
    }
    if (pExposure->GetValue(Exposure).IsOK() == false) {
        return -2;
    }

    *RetVal = Exposure;

    return 0;

}
int SetExposure(double Exposure) {

    PvGenParameterArray* pParameterArray = pDevice->GetParameters();
    PvGenParameter* pParameter = pParameterArray->Get("ExposureTime");
    PvGenFloat* pExposure = dynamic_cast<PvGenFloat*>(pParameter);
    if (pExposure == NULL) {
        return -1;
    }
    if (pExposure->SetValue(Exposure).IsOK() == false) {
        return -2;
    }

    return 0;

}
