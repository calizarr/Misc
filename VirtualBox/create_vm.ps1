param(
    [string] $Name,
    [string] $BaseFolder,
    [string] $IsoFile,
    [string] $HddSize = "256000",
    [string] $CpuCount = "4",
    [string] $RamSize = "8192",
    [string] $VRamSize = "256",
    [bool] $DryRun = $false,
    [bool] $Verbose = $false,
    [bool] $StartVM = $false
)

<# Example Command: .\create_vm.ps1 -Name nanaya -BaseFolder I:\Virtualization\Virtualbox\ -IsoFile G:Virtualization\ubuntu-18.04.1-desktop-amd64.iso -DryRun $true -StartVM $true #>
$HddFilename = [IO.Path]::Combine($BaseFolder, "${Name}_OS_Ubuntu-64.vdi")
Function DryRunVerboseExec {
    $Command = $args[0]
    if ($DryRun) { 
        Write-Host $Command
    } elseif ($Verbose) {
        Write-Host $Command
        Invoke-Expression $Command
    } else {
        Invoke-Expression $Command
    }
}

Write-Host "The VM name will be: $Name"
Write-Host "The VM machine folder path name will be: $BaseFolder"

# Create and register the Ubuntu Virtual Machine
$CreateCommand =  "VBoxManage createvm --name $Name --ostype Ubuntu_64 --basefolder $BaseFolder --register"
DryRunVerboseExec($CreateCommand)

# Modify the virtual machine to give it all the necessary networking, virtualization, 3d acceleration, and clipboard usage etc.
# --nic1 natnetwork --nat-network1 NatNetwork 
$FlagArray = @(
    "--hwvirtex on", "--x2apic on", "--pae on", "--nestedpaging on", "--nested-hw-virt on",
    "--accelerate3d on", "--graphicscontroller 'VMSVGA'",
    "--clipboard-mode bidirectional", "--draganddrop bidirectional",
    "--nic1 nat", "--nic2 hostonly", "--hostonlyadapter2 'VirtualBox Host-Only Ethernet Adapter #2'",
    "--cableconnected2 off","--usbxhci on"
    )
$DefaultFlags = $FlagArray -join(" ")
$ModifyCommand = "VBoxManage modifyvm $Name --memory $RamSize --vram $VRamSize --cpus $CpuCount"
DryRunVerboseExec("$ModifyCommand $DefaultFlags")

# Set up the Optical Drive and mount the ISO
$DVDCreate = "VBoxManage storagectl $Name --name 'IDE Controller' --add ide --controller PIIX4 --hostiocache on --bootable on"
DryRunVerboseExec($DVDCreate)
$DVDAttach = "VBoxManage storageattach $Name --storagectl 'IDE Controller' --type dvddrive --port 0 --device 0 --medium $IsoFile"
DryRunVerboseExec($DVDAttach)

# Add a 250 GB disk
$StorageCreate = "VBoxManage storagectl $Name --name 'Disk Controller' --add sata --controller IntelAHCI --hostiocache on --bootable on"
$StorageHdd = "VBoxManage createmedium disk --filename $HddFilename --size $HddSize --format VDI"
$StorageAttach = "VBoxManage storageattach $Name --storagectl 'Disk Controller' --port 0 --device 0 --type hdd --medium $HddFilename"

DryRunVerboseExec($StorageCreate)
DryRunVerboseExec($StorageHdd)
DryRunVerboseExec($StorageAttach)

if ($StartVM) {
    $StartCommand = "VBoxManage startvm $Name --type gui"
    DryRunVerboseExec($StartCommand)
}