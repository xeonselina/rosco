FROM gcr.io/spinnaker-marketplace/gradle_cache as compile
MAINTAINER delivery-engineering@netflix.com
ENV GRADLE_USER_HOME /gradle_cache/.gradle
COPY . compiled_sources
WORKDIR compiled_sources
RUN ./gradlew --no-daemon rosco-web:installDist -x test

FROM openjdk:8-jre-alpine
MAINTAINER delivery-engineering@netflix.com
COPY --from=compile /compiled_sources/rosco-web/build/install/rosco /opt/rosco
COPY --from=compile /compiled_sources/rosco-web/config              /opt/rosco
COPY --from=compile /compiled_sources/rosco-web/config/packer       /opt/rosco/config/packer

COPY --from=compile /compiled_sources/coding-deploy/config /opt/spinnaker/config
COPY --from=compile /compiled_sources/coding-deploy/packer /opt/rosco/config/packer
COPY --from=compile /compiled_sources/coding-deploy/scripts /opt/rosco/config/packer/scripts

WORKDIR /packer

RUN apk --no-cache add --update bash wget curl openssl 
RUN wget https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip && \
  unzip packer_1.5.1_linux_amd64.zip && \
  rm packer_1.5.1_linux_amd64.zip

ENV PATH "/packer:$PATH"

RUN wget https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get && \
  chmod +x get && \
  ./get && \
  rm get

RUN mkdir kustomize && \
  curl -s -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz |\
  tar xvz -C kustomize/

ENV PATH "kustomize:$PATH"
ENV TENCENTCLOUD_SECRET_ID AKIDl661NCPAF3eMp2C3lDpKflbKq55KdAj7
ENV TENCENTCLOUD_SECRET_KEY TjodQzIM53mNlupXzMZZIlz0lFe8PRDk

RUN adduser -D -S spinnaker

USER spinnaker
CMD ["/opt/rosco/bin/rosco"]
