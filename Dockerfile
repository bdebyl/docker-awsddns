FROM bdebyl/awscli
MAINTAINER Bastian de Byl <bastian@bdebyl.net>

RUN apk --update add curl jq \
    && rm /var/cache/apk/*

ADD src/awsddns.sh /etc/periodic/15min/awsddns

CMD ["-f", "-d", "8"]
ENTRYPOINT ["crond"]
