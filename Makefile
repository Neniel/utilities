VERSION ?=

DIST_DIR := dist
NAME := utilities


validate:
ifndef NAME
	$(error Error: Utility name must be provided. Use: make zip VERSION=MAJOR.MINOR.PATCH)
endif
	@if [ ! -d "$(NAME)" ]; then \
		echo "Error: Invalid utility name: '$(NAME)'"; \
		exit 1; \
	fi

ifndef VERSION
	$(error Error: Version must be provided. Uso: make zip NAME=utility_name VERSION=MAJOR.MINOR.PATCH)
endif
	@if ! echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Error: Invalid version format: '$(VERSION)'. Must match SemVer (eg: 1.2.3)"; \
		exit 1; \
	fi

.PHONY: clear zip validate install

clear:
	@find . -type d -name $(DIST_DIR) -exec rm -rf {} +

zip:
	rm -rf ./$(DIST_DIR)/$(NAME)
	mkdir -p ./$(DIST_DIR)/$(NAME)

	cp -r ./modules ./$(DIST_DIR)/$(NAME)/
	mkdir ./$(DIST_DIR)/$(NAME)/modules/private
	cp ./utilities.sh ./$(DIST_DIR)/$(NAME)/
	echo "$(NAME) version $(VERSION)" > ./$(DIST_DIR)/$(NAME)/.version

	@echo "Packing utility '$(NAME)'..."
	cd $(DIST_DIR)/$(NAME) && zip -r ../$(NAME)-$(VERSION).zip ./

	@echo "Limpiando archivos temporales..."
	rm -rf ./$(DIST_DIR)/$(NAME)
	mkdir -p ./$(DIST_DIR)/$(NAME)

	# Mover el zip a la carpeta final
	mv ./$(DIST_DIR)/$(NAME)-$(VERSION).zip ./$(DIST_DIR)/$(NAME)/

	@echo "Utility '$(NAME)' has been packed."
	unzip -l ./$(DIST_DIR)/$(NAME)/$(NAME)-$(VERSION).zip

install: validate
	unzip ./$(DIST_DIR)/$(NAME)/$(NAME)_$(VERSION).zip -d ~

tag:
	git push --delete origin release/$(VERSION) || true
	git tag -fa release/$(VERSION) -m "release/$(VERSION)" && git push origin tag release/$(VERSION)
