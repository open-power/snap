// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#include "xparameters.h"
#include "xhls_action.h"

extern XHls_action_Config XHls_action_ConfigTable[];

XHls_action_Config *XHls_action_LookupConfig(u16 DeviceId) {
	XHls_action_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XHLS_ACTION_NUM_INSTANCES; Index++) {
		if (XHls_action_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XHls_action_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XHls_action_Initialize(XHls_action *InstancePtr, u16 DeviceId) {
	XHls_action_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XHls_action_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XHls_action_CfgInitialize(InstancePtr, ConfigPtr);
}

#endif

