FROM poldracklab/fmriprep:latest
MAINTAINER Asier Erramuzpe <asier.erramuzpe@gmail.com>

WORKDIR /

# Core system capabilities required
RUN apt-get update && apt-get install -y curl git perl-modules python software-properties-common tar unzip wget
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs

# Now that we have software-properties-common, can use add-apt-repository to get to g++ version 5, which is required by JSON for Modern C++
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update && apt-get install -y g++-5

# Additional dependencies for MRtrix3 compilation
RUN apt-get install -y libeigen3-dev zlib1g-dev

# Neuroimaging software / data dependencies
RUN apt-get install -y fsl-5.0-core
RUN apt-get install -y fsl-first-data
RUN apt-get install -y fsl-mni152-templates
#RUN apt-get install -y fsl-5.0-eddy-nonfree # Use direct download instead (below) - more up-to-date version
RUN rm -f `which eddy`
RUN mkdir /opt/eddy/
RUN wget -qO- https://fsl.fmrib.ox.ac.uk/fsldownloads/patches/eddy-patch-fsl-5.0.9/centos6/eddy_openmp > /opt/eddy/eddy_openmp
RUN chmod 775 /opt/eddy/eddy_openmp
RUN wget -qO- https://bitbucket.org/reisert/unring/get/8e5eeba67a1d.zip -O unring.zip && unzip -qq -o unring.zip -d /opt/ && rm -f unring.zip
RUN wget -qO- http://www.gin.cnrs.fr/AAL_files/aal_for_SPM12.tar.gz | tar zxv -C /opt
RUN wget -qO- http://www.gin.cnrs.fr/AAL2_files/aal2_for_SPM12.tar.gz | tar zxv -C /opt
RUN wget -qO- http://www.nitrc.org/frs/download.php/4499/sri24_anatomy_nifti.zip -O sri24_anatomy_nifti.zip && unzip -qq -o sri24_anatomy_nifti.zip -d /opt/ && rm -f sri24_anatomy_nifti.zip
RUN wget -qO- http://www.nitrc.org/frs/download.php/4508/sri24_labels_nifti.zip -O sri24_labels_nifti.zip && unzip -qq -o sri24_labels_nifti.zip -d /opt/ && rm -f sri24_labels_nifti.zip

RUN npm install -g bids-validator

# MRtrix3 setup
ENV CXX=/usr/bin/g++-5
# Note: Current commit being checked out includes various fixes that have been necessary to get test data working; eventually it will instead point to a release tag that includes these updates
RUN git clone https://github.com/MRtrix3/mrtrix3.git mrtrix3 && cd mrtrix3 && git checkout 54faeb61 && python configure -nogui && NUMBER_OF_PROCESSORS=1 python build && git describe --tags > /mrtrix3_version
#RUN echo $'FailOnWarn: 1\n' > /etc/mrtrix.conf

# Setup environment variables
ENV FSLDIR=/usr/share/fsl/5.0
ENV FSLMULTIFILEQUIT=TRUE
# Note: Would prefer NIFTI, but need to stick to compressed for now due to FSL Ubuntu not honoring this variable. May be able to revert once fsl.checkFirst() is merged in.
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV LD_LIBRARY_PATH=/usr/lib/fsl/5.0
ENV PATH=/opt/freesurfer/bin:/opt/freesurfer/mni/bin:/usr/lib/fsl/5.0:/usr/lib/ants:/mrtrix3/bin:/opt/reisert-unring-8e5eeba67a1d/fsl/:/opt/eddy:$PATH
ENV PYTHONPATH=/mrtrix3/lib

RUN conda install -y --channel conda-forge nilearn==0.3.1 \
                                           dipy==0.13.0 \
                                           nipype==0.14.0

# Acquire script to be executed
COPY run.py /run.py
RUN chmod 775 /run.py

ENTRYPOINT []