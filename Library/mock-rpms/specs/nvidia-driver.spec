Name:       nvidia-driver
Version:    %{driver_version}
Release:    1
Epoch:      3
Summary:    Empty NVIDIA driver fixture for radii tests
License:    GPL-3.0-or-later
BuildArch:  noarch
%if 0%{?build_stack}
Requires:   nvidia-kmod = %{epoch}:%{version}
%endif

%description
Metadata-only driver package for available and installed version discovery.

%files

%if 0%{?build_stack}

%package -n nvidia-driver-cuda
Summary:    Empty nvidia-driver-cuda fixture for radii tests
Requires:   nvidia-driver = %{epoch}:%{version}

%description -n nvidia-driver-cuda
Metadata-only companion package for NVIDIA installation tests.

%files -n nvidia-driver-cuda

%package -n nvidia-fabricmanager
Summary:    Empty nvidia-fabricmanager fixture for radii tests
Requires:   nvidia-driver = %{epoch}:%{version}

%description -n nvidia-fabricmanager
Metadata-only companion package for NVIDIA installation tests.

%files -n nvidia-fabricmanager

%package -n nvidia-fabric-manager-devel
Summary:    Empty nvidia-fabric-manager-devel fixture for radii tests
Requires:   nvidia-fabricmanager = %{epoch}:%{version}

%description -n nvidia-fabric-manager-devel
Metadata-only companion package for NVIDIA installation tests.

%files -n nvidia-fabric-manager-devel

%package -n cublasmp
Summary:    Empty cublasmp fixture for radii tests

%description -n cublasmp
Metadata-only companion package for NVIDIA installation tests.

%files -n cublasmp

%package -n cuda-compat
Summary:    Empty cuda-compat fixture for radii tests

%description -n cuda-compat
Metadata-only companion package for NVIDIA installation tests.

%files -n cuda-compat

%package -n cuda-toolkit
Summary:    Empty cuda-toolkit fixture for radii tests

%description -n cuda-toolkit
Metadata-only companion package for NVIDIA installation tests.

%files -n cuda-toolkit

%package -n cudnn
Summary:    Empty cudnn fixture for radii tests

%description -n cudnn
Metadata-only companion package for NVIDIA installation tests.

%files -n cudnn

%package -n dnf-plugin-nvidia
Summary:    Empty dnf-plugin-nvidia fixture for radii tests

%description -n dnf-plugin-nvidia
Metadata-only companion package for NVIDIA installation tests.

%files -n dnf-plugin-nvidia

%package -n libnccl-devel
Summary:    Empty libnccl-devel fixture for radii tests

%description -n libnccl-devel
Metadata-only companion package for NVIDIA installation tests.

%files -n libnccl-devel

%package -n libnccl-static
Summary:    Empty libnccl-static fixture for radii tests

%description -n libnccl-static
Metadata-only companion package for NVIDIA installation tests.

%files -n libnccl-static

%endif
