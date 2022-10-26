FROM nixos/nix

RUN nix-channel --update

RUN echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf

WORKDIR /build

CMD [ "/root/.nix-profile/bin/bash", "-c", "rm -rf ./iso && mkdir -p ./ssh && mkdir -p ./iso && ssh-keygen -t rsa -b 4096 -C 'developer@local' -f './ssh/id_rsa' -N '' -y && nix build . && cp -rL ./result/iso/nixos.iso ./iso/nixos.iso && rm -rf ./result && chmod 600 ./ssh/id_rsa"]

