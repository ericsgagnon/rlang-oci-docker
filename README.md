# rlang-oci-docker

Multistage docker build extending rocker image with oracle oci

1. Oracle Instant Client: using oracle linux to install instant client per

    https://github.com/oracle/docker-images/blob/master/OracleInstantClient

2. R: copy OIC (with OCI) from previous stage into rocker/geospatial image and set oracle env variables
3. Install ROracle
