#### Environment Variables ####
# Allow override of env file path
ENV_FILE ?= .env

include $(ENV_FILE)
set-env:
	$(eval export $(shell cat $(ENV_FILE) | xargs))


#### Python Environment ####
.PHONY: install
install: 
	pip install -r ./requirements-build.txt
	pip install -r ./requirements.txt
	pip install -r ./requirements-dev.txt

.PHONY: uninstall
uninstall:
	@bash -c "pip uninstall -y -r <(pip freeze)"

#### Testing ####
TEST_COMMANDS = \
	--cov=dockmaster \
	--cov-config=setup.cfg \
	--cov-report html \
	--cov-report term

.PHONY: test
test: test.clean test.unit 
	rm -rf htmlcov/
	rm -f .coverage

.PHONY: test.clean
test.clean:
	rm -rf htmlcov/
	rm -f .coverage

.PHONY: test.unit
test.unit: 
	pytest -rfEP $(TEST_COMMANDS) tests

#### Code Style ####
FORMAT_DIRS = src/ test/
LINT_DIRS = src/ test/

.PHONY: lint
lint:
	ruff check $(LINT_DIRS)

.PHONY: format
format:
	ruff format $(FORMAT_DIRS)

#### Build/Publish ####
# --- Version from package
PACKAGE_NAME=dockmaster
PACKAGE_VERSION=`grep version setup.cfg | awk '{print $$3}'`
GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
GIT_SHA=`git rev-parse --short HEAD`
# Set TAGNAME based on branch
ifeq ($(GIT_BRANCH),main)
    TAGNAME=v$(PACKAGE_VERSION)
else
    TAGNAME=v$(PACKAGE_VERSION)-$(GIT_BRANCH)-$(GIT_SHA)
endif
DOCKER_IMAGE ?= $(or $(DOCKER_IMAGE),dockmaster)

# --- Local build ---
.PHONY: publish.info
publish.info:
	@echo "Package: $(PACKAGE_NAME)"
	@echo "Package Version: $(PACKAGE_VERSION)"
	@echo "Tagname: $(TAGNAME)"
	@echo "Docker tag: $(TAGNAME)"
	@echo "Docker image: $(DOCKER_IMAGE)"

.PHONY: publish.setup
publish.setup:
	@echo "---Recreating setup.cfg file "
	@bash -c "./setup.cfg.sh"
	git add setup.cfg src/dockyard/__init__.py
	@echo "---Committing+Pushing setup file changes"
	git commit -m"$(TAGNAME): creating setup.cfg" --allow-empty
	git push -u origin HEAD

.PHONY: publish.build
publish.build:
	@echo "---Building Project..."
	@rm -rf dist/* 
	python -m build -n

.PHONY: publish.tag
publish.tag:
	@echo "---Tagging commit hash $(TAGNAME)"
	git tag -a $(TAGNAME) -m "Release $(TAGNAME)"
	git push origin $(TAGNAME)
	@echo "---Pushed tag as version=$(PACKAGE_VERSION)"

#### Docker Commands ####
.PHONY: docker.help
docker.help:
	@echo "Docker commands:"
	@echo "  make docker.build      - Build Docker image and tag for production"
	@echo "  make docker.push       - Push to Google Artifact Repository"

# ---- Development ----
.PHONY: docker.dev.build
docker.dev.build:
	# Build and tag for dev
	docker build -t $(DOCKER_IMAGE):dev .

.PHONY: docker.dev.shell
docker.dev.shell:
	@echo "Opening dev container with shell..."
	docker run --rm -it --name dockyard-dev $(DOCKER_IMAGE):dev bash

.PHONY: docker.dev.run
docker.dev.run:
	@echo "Running dev container..."
	docker run --rm -it -p 8000:8000 --name dockyard-dev $(DOCKER_IMAGE):dev

.PHONY: docker.dev.clean
docker.dev.clean:
	@echo "Stopping dev container..."
	docker stop $(DOCKER_IMAGE):dev 2>/dev/null || true
	@echo "Removing dev container..."
	docker rm $(DOCKER_IMAGE):dev -f

# ---- Production ----
.PHONY: docker.build
docker.build:
	# Build and tag for local
	docker build -t $(DOCKER_IMAGE):$(TAGNAME) .
	# Tag for Artifact Registry
	docker tag $(DOCKER_IMAGE):$(TAGNAME) $(ARTIFACT_REGISTRY_HOST)/$(DOCKER_IMAGE):$(TAGNAME)
	docker tag $(DOCKER_IMAGE):$(TAGNAME) $(ARTIFACT_REGISTRY_HOST)/$(DOCKER_IMAGE):latest

.PHONY: docker.push
docker.push:
	@echo "Pushing dockmaster image to GAR..."
	docker push ${ARTIFACT_REGISTRY_HOST}/${DOCKER_IMAGE}:$(TAGNAME)
	docker push ${ARTIFACT_REGISTRY_HOST}/${DOCKER_IMAGE}:latest
	@echo "Push completed successfully"

#### Context ####
.PHONY: context
context: context.clean context.src context.public context.settings

.PHONY: context.src
context.src:
	repo2txt -r ./src/ -o ./context/context-src.txt \
	&& python -c 'import sys; open("context/context-src.md","wb").write(open("context/context-src.txt","rb").read().replace(b"\0",b""))' \
	&& rm ./context/context-src.txt

.PHONY: context.settings
context.settings:
	repo2txt -r . -o ./context/context-settings.txt \
	--exclude-dir context src notebooks \
	--ignore-types .md \
	--ignore-files LICENSE README.md \
	&& python -c 'import sys; open("context/context-settings.md","wb").write(open("context/context-settings.txt","rb").read().replace(b"\0",b""))' \
	&& rm ./context/context-settings.txt

.PHONY: context.clean
context.clean:
	rm ./context/context-*

#### Development ####
.PHONY: jupyter
jupyter: 
	@jupyter lab --autoreload --no-browser

.PHONY: fastapi.dev
fastapi.dev:
	@echo "Starting FastAPI server for development..."
	@fastapi dev src/dockmaster/main.py --reload