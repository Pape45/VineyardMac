/*
 * This file is part of Whisky.
 *
 * Whisky is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 */

#define COBJMACROS
#include <initguid.h>
#include <d3d11.h>
#include <d3d12.h>
#include <stdio.h>
#include <string.h>

static int test_d3d11(void) {
    typedef HRESULT (WINAPI *CreateDevice)(
        IDXGIAdapter *, D3D_DRIVER_TYPE, HMODULE, UINT, const D3D_FEATURE_LEVEL *, UINT,
        UINT, ID3D11Device **, D3D_FEATURE_LEVEL *, ID3D11DeviceContext **
    );
    HMODULE library = LoadLibraryA("d3d11.dll");
    D3D_FEATURE_LEVEL level;
    ID3D11Device *device11 = NULL;
    ID3D11DeviceContext *context = NULL;
    FARPROC symbol;
    HRESULT result;
    CreateDevice create_device;

    if (library == NULL) {
        fprintf(stderr, "Loading d3d11.dll failed: %lu\n", GetLastError());
        return 10;
    }
    symbol = GetProcAddress(library, "D3D11CreateDevice");
    if (symbol == NULL) {
        fprintf(stderr, "Finding D3D11CreateDevice failed: %lu\n", GetLastError());
        return 10;
    }
    memcpy(&create_device, &symbol, sizeof(create_device));

    result = create_device(
        NULL,
        D3D_DRIVER_TYPE_HARDWARE,
        NULL,
        0,
        NULL,
        0,
        D3D11_SDK_VERSION,
        &device11,
        &level,
        &context
    );
    if (FAILED(result)) {
        fprintf(stderr, "D3D11CreateDevice failed: 0x%08lx\n", (unsigned long)result);
        return 11;
    }
    printf("D3D11 feature level: 0x%x\n", level);
    ID3D11DeviceContext_Release(context);
    ID3D11Device_Release(device11);
    FreeLibrary(library);
    return 0;
}

static int test_d3d12(void) {
    typedef HRESULT (WINAPI *CreateDevice)(IUnknown *, D3D_FEATURE_LEVEL, REFIID, void **);
    HMODULE library = LoadLibraryA("d3d12.dll");
    ID3D12Device *device12 = NULL;
    FARPROC symbol;
    HRESULT result;
    CreateDevice create_device;

    if (library == NULL) {
        fprintf(stderr, "Loading d3d12.dll failed: %lu\n", GetLastError());
        return 10;
    }
    symbol = GetProcAddress(library, "D3D12CreateDevice");
    if (symbol == NULL) {
        fprintf(stderr, "Finding D3D12CreateDevice failed: %lu\n", GetLastError());
        return 10;
    }
    memcpy(&create_device, &symbol, sizeof(create_device));

    result = create_device(
        NULL,
        D3D_FEATURE_LEVEL_11_0,
        &IID_ID3D12Device,
        (void **)&device12
    );
    if (FAILED(result)) {
        fprintf(stderr, "D3D12CreateDevice failed: 0x%08lx\n", (unsigned long)result);
        return 12;
    }
    puts("D3D12 device created");
    ID3D12Device_Release(device12);
    FreeLibrary(library);
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fputs("Usage: directx.exe d3d11|d3d12\n", stderr);
        return 64;
    }
    if (strcmp(argv[1], "d3d11") == 0) {
        return test_d3d11();
    }
    if (strcmp(argv[1], "d3d12") == 0) {
        return test_d3d12();
    }
    fputs("Usage: directx.exe d3d11|d3d12\n", stderr);
    return 64;
}
