%if "%{kernel_variant}" == "64k"
%global variant_suffix -64k
ExclusiveArch: aarch64
%else
%global variant_suffix %{nil}
ExclusiveArch: x86_64 aarch64
%endif

Name:       kmod%{variant_suffix}-nvidia-open-%{driver_version}-%{kernel_name_version}
Version:    %{driver_version}
Release:    3.%{kernel_dist}
Epoch:      3
Summary:    Empty NVIDIA kernel module fixture for radii tests
License:    GPL-3.0-or-later

Provides:   kernel%{variant_suffix}-modules = %{kernel_version}.%{_target_cpu}
Provides:   nvidia-kmod = %{epoch}:%{version}
Provides:   kmod-nvidia-open = %{epoch}:%{version}
%if "%{kernel_variant}" == "64k"
Provides:   kmod-64k-nvidia-open = %{epoch}:%{version}
%endif

Supplements: (nvidia-driver = %{epoch}:%{version} and kernel = %{kernel_version})
Requires:   (kernel%{variant_suffix} = %{kernel_version} if kernel%{variant_suffix})
Conflicts:  kmod-nvidia-latest-dkms
Conflicts:  kmod-nvidia-open-dkms
Conflicts:  kmod-nvidia
Recommends: dnf-plugin-nvidia

%description
Metadata-only package preserving NVIDIA kernel module dependency semantics.

%files
