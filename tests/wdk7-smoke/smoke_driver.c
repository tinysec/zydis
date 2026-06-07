#include <wdm.h>
#include <Zydis/Zydis.h>

DRIVER_INITIALIZE DriverEntry;

#ifdef ALLOC_PRAGMA
#pragma alloc_text(INIT, DriverEntry)
#endif

static NTSTATUS
ZydisSmokeDecode(void)
{
    ZydisDecoder decoder;
    ZydisDecoderContext context;
    ZydisDecodedInstruction instruction;
    ZyanStatus status;
    const ZyanU8 code[1] = { 0x90 };

#if defined(_M_AMD64)
    status = ZydisDecoderInit(&decoder, ZYDIS_MACHINE_MODE_LONG_64, ZYDIS_STACK_WIDTH_64);
#else
    status = ZydisDecoderInit(&decoder, ZYDIS_MACHINE_MODE_LEGACY_32, ZYDIS_STACK_WIDTH_32);
#endif
    if (!ZYAN_SUCCESS(status))
    {
        return STATUS_UNSUCCESSFUL;
    }

    status = ZydisDecoderDecodeInstruction(&decoder, &context, code, sizeof(code), &instruction);
    if (!ZYAN_SUCCESS(status))
    {
        return STATUS_UNSUCCESSFUL;
    }

    if (instruction.mnemonic != ZYDIS_MNEMONIC_NOP)
    {
        return STATUS_UNSUCCESSFUL;
    }

    if (ZydisGetVersion() != ZYDIS_VERSION)
    {
        return STATUS_UNSUCCESSFUL;
    }

    return STATUS_SUCCESS;
}

NTSTATUS
DriverEntry(
    PDRIVER_OBJECT DriverObject,
    PUNICODE_STRING RegistryPath
    )
{
    UNREFERENCED_PARAMETER(DriverObject);
    UNREFERENCED_PARAMETER(RegistryPath);

    return ZydisSmokeDecode();
}
