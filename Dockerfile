FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel

ARG DEBIAN_FRONTEND=noninteractive
ARG TORCH_ARCH="7.0;7.5;8.0;8.6+PTX"
ENV TORCH_CUDA_ARCH_LIST=${TORCH_ARCH}
ENV MAX_JOBS=4
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 \
    libxrender1 libgomp1 libopengl0 && rm -rf /var/lib/apt/lists/*

RUN conda create -n surfel_splatting python=3.10 pip -y && conda clean -afy
RUN conda run -n surfel_splatting python -m pip install \
    torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121
RUN conda run -n surfel_splatting python -m pip install \
    'setuptools<75' wheel ninja 'numpy<2' open3d==0.18.0 mediapy==1.1.2 \
    lpips==0.1.4 scikit-image==0.21.0 tqdm==4.66.2 trimesh==4.3.2 \
    plyfile 'opencv-python<4.10' tensorboard

WORKDIR /home/appuser/2dgs
COPY . .
# Apply the CUDA source fix documented in this fork's README.
RUN cp scripts_error/simple_knn.cu submodules/simple-knn/simple_knn.cu && \
    conda run --no-capture-output -n surfel_splatting python -m pip install \
    --no-build-isolation ./submodules/diff-surfel-rasterization ./submodules/simple-knn

RUN conda create -n postprocess python=3.10 pip -y && conda clean -afy && \
    conda run -n postprocess python -m pip install \
    pymeshlab==2023.12.post3 'numpy<2' scipy

ENV CONDA_DEFAULT_ENV=surfel_splatting
SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash", "-c", "source activate surfel_splatting && exec bash"]
