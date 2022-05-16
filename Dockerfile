FROM rocker/shiny:4.1

LABEL maintainer="Sen ZHAO <t.cytotoxic@gmail.com>"

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
	build-essential=12.8ubuntu1.1 \
	sudo=1.8.31-1ubuntu1.2 \
	unzip=6.0-25ubuntu1 \
	wget=1.20.3-1ubuntu2 \
	curl=7.68.0-1ubuntu2.11 \
	git=1:2.25.1-1ubuntu3.4 \
	libbz2-dev=1.0.8-2 \
	zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.3 \
	libgsl-dev=2.5+dfsg-6build1 \
	liblzma-dev=5.2.4-1ubuntu1.1 \
	libglpk-dev=4.65-2 \
	libncurses5-dev=6.2-0ubuntu2 \
	libperl-dev=5.30.0-9ubuntu0.2 \
	zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.3 \
	libcurl4-openssl-dev=7.68.0-1ubuntu2.11 \
	libxt-dev=1:1.1.5-1 \
	libcairo2-dev=1.16.0-4ubuntu1 \
	libsqlite3-dev=3.31.1-4ubuntu0.3 \
	libpng-dev=1.6.37-2 \
	libjpeg-dev=8c-2ubuntu8 \
	libxml2-dev=2.9.10+dfsg-5ubuntu0.20.04.2 \
	libssl-dev=1.1.1f-1ubuntu2.13 \
	libssh2-1-dev=1.8.0-2.1build1 \
    && rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib/R/lib/
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/R/lib/

WORKDIR /tmp
ARG htsversion=1.13
RUN curl -L https://github.com/samtools/htslib/releases/download/${htsversion}/htslib-${htsversion}.tar.bz2 | tar xj && \
    (cd htslib-${htsversion} && ./configure --enable-plugins --with-plugin-path='$(libexecdir)/htslib:/usr/libexec/htslib' && make install) && \
    ldconfig && \
    curl -L https://github.com/samtools/samtools/releases/download/${htsversion}/samtools-${htsversion}.tar.bz2 | tar xj && \
    (cd samtools-${htsversion} && ./configure --with-htslib=system && make install) && \
    curl -L https://github.com/samtools/bcftools/releases/download/${htsversion}/bcftools-${htsversion}.tar.bz2 | tar xj && \
    (cd bcftools-${htsversion} && ./configure --enable-libgsl --enable-perl-filters --with-htslib=system && make install)

RUN install2.r -e remotes
RUN install2.r -e devtools
RUN installGithub.r "lchiffon/wordcloud2"
RUN installGithub.r "senzhaocode/FuSViz"
RUN wget https://cran.r-project.org/src/contrib/Archive/shinyWidgets/shinyWidgets_0.6.2.tar.gz && R CMD INSTALL shinyWidgets_0.6.2.tar.gz
RUN rm -rf /tmp/bcftools* && rm -rf /tmp/htslib-* && rm -rf /tmp/samtools-* && rm -rf /tmp/file* && rm -rf /tmp/shinyWidgets*

RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" >> /usr/local/lib/R/etc/Rprofile.site

# Set Volume
RUN mkdir /data && chmod 777 /data
VOLUME /data

# Final clean
RUN apt-get clean autoclean
RUN rm -rf /var/tmp/*
RUN rm -rf /tmp/downloaded_packages

# Set non-root user
RUN addgroup --system senzhao && adduser --system --ingroup senzhao senzhao

WORKDIR /home/senzhao

COPY inst/app/*.R ./

RUN chown senzhao:senzhao -R /home/senzhao

USER senzhao

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/home/senzhao')"]

