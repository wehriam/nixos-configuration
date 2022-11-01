NIXADDR ?= nixos

iso:
	echo ""
	echo "Building docker image"
	docker build -t nixos-builder:latest .
	
	echo ""
	echo "Running docker container"
	docker run -v $(shell pwd):/build nixos-builder:latest

bootstrap:
	rsync -av -e 'ssh -i ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
		--exclude='.git/' \
		--exclude='iso/' \
		--exclude='Dockerfile' \
		--exclude='Makefile' \
		--exclude='ssh/id_rsa' \
		--exclude='.git-crypt/' \
		--rsync-path="sudo rsync" \
		$(shell pwd)/ developer@$(NIXADDR):/nix-config
	ssh -i ssh/id_rsa \
		-o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		developer@$(NIXADDR) \ " \
		sudo parted /dev/nvme0n1 -- mklabel gpt; \
		sudo parted /dev/nvme0n1 -- mkpart primary 512MiB -8GiB; \
		sudo parted /dev/nvme0n1 -- mkpart primary linux-swap -8GiB 100\%; \
		sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB; \
		sudo parted /dev/nvme0n1 -- set 3 esp on; \
		sleep 1; \
		sudo mkfs.ext4 -L nixos /dev/nvme0n1p1; \
		sudo mkswap -L swap /dev/nvme0n1p2; \
		sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p3; \
		sleep 1; \
		sudo mkdir -p /mnt; \
		sudo mount /dev/disk/by-label/nixos /mnt; \
		sudo mkdir -p /mnt/boot; \
		sudo mount /dev/disk/by-label/boot /mnt/boot; \
		sudo nix-channel --update; \
		sudo nixos-install --no-root-passwd --flake \"/nix-config#nixos\"; \
		sudo reboot; \
	"

update:
	rsync -av -e 'ssh -i ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
		--exclude='.git/' \
		--exclude='iso/' \
		--exclude='Dockerfile' \
		--exclude='Makefile' \
		--exclude='ssh/id_rsa' \
		--exclude='.git-crypt/' \
		--rsync-path="sudo rsync" \
		$(shell pwd)/ developer@$(NIXADDR):/nix-config
	ssh -i ssh/id_rsa \
		-o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		developer@$(NIXADDR) \ " \
			sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/nix-config#nixos\"; \
		"

format:
	docker run -v $(shell pwd):/build --rm -t nixos-builder:latest nixpkgs-fmt /build