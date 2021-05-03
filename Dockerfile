FROM rabbitmq:3.8

RUN rabbitmq-plugins enable rabbitmq_management
RUN rabbitmq-plugins enable rabbitmq_mqtt
RUN set -eux; \
    	erl -noinput -eval ' \
	            { ok, AdminBin } = zip:foldl(fun(FileInArchive, GetInfo, GetBin, Acc) -> \
	                    case Acc of \
	                            "" -> \
										case lists:suffix("/rabbitmqadmin", FileInArchive) of \
												true -> GetBin(); \
												false -> Acc \
										end; \
								_ -> Acc \
						end \
				end, "", init:get_plain_arguments()), \
				io:format("~s", [ AdminBin ]), \
				init:stop(). \
		' -- /plugins/rabbitmq_management-*.ez > /usr/local/bin/rabbitmqadmin; \
		[ -s /usr/local/bin/rabbitmqadmin ]; \
		chmod +x /usr/local/bin/rabbitmqadmin; \
		apt-get update; \
		apt-get install -y --no-install-recommends python3 openssl; \
		rm -rf /var/lib/apt/lists/*; \
		rabbitmqadmin --version; \
		mkdir -p /home/testca/certs; \
		mkdir -p /home/testca/private; \
		chmod 700 /home/testca/private; \
		echo 01 > /home/testca/serial; \
		touch /home/testca/index.txt;

COPY rabbitmq.config /etc/rabbitmq/rabbitmq.config
COPY openssl.cnf /home/testca
COPY prepare-server.sh generate-client-keys.sh /home/

RUN mkdir -p /home/server \
	&& mkdir -p /home/client \
	&& chmod +x /home/prepare-server.sh /home/generate-client-keys.sh

RUN /bin/bash /home/prepare-server.sh \
	&& invoke-rc.d rabbitmq-server start

CMD /bin/bash /home/generate-client-keys.sh && rabbitmq-server
#sleep infinity
