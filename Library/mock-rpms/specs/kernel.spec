Name:       radii-mock-kernel%{kernel_suffix}-%{kernel_release}
Version:    1.0
Release:    1
Summary:    Empty kernel dependency provider for radii tests
License:    GPL-3.0-or-later
BuildArch:  noarch
Provides:   kernel%{kernel_suffix} = %{kernel_release}

%description
Satisfy mock kmod dependencies without installing a bootable kernel.

%files
