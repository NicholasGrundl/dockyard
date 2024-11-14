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

.PHONY: pre-commit
pre-commit: format lint test

.PHONY: lint
lint:
	ruff check $(LINT_DIRS)

.PHONY: format
format:
	ruff format $(FORMAT_DIRS)

#### Build/Publish ####
# --- Env vars
-include .env.publish
ARTIFACT_REGISTRY_HOST ?= $(or $(ARTIFACT_REGISTRY_HOST),us-west1-docker.pkg.dev/)
DOCKER_IMAGE ?= $(or $(DOCKER_IMAGE),dockyard)

# --- Version from package
VERSION=`grep version setup.cfg | awk '{print $$3}'`
TAGNAME=v$(VERSION)
DOCKER_TAG=$(VERSION)

# # --- Local build ---
# .PHONY: publish.build
# build:
# 	@echo "Building frontend..."
# 	npm run build

.PHONY: publish.tag
publish.tag:
	@echo "---Tagging commit hash $(TAGNAME)"
	git tag -a $(TAGNAME) -m "Release $(TAGNAME)"
	git push origin $(TAGNAME)
	@echo "---Pushed tag as version=$(VERSION)"

#### Docker Commands ####
.PHONY: docker.help
docker.help:
	@echo "Docker commands:"
	@echo "  make docker.build      - Build Docker image and tag for production"
	@echo "  make docker.build.dev  - Build Docker image for local development"
	@echo "  make docker.push       - Push to Google Artifact Repository"

.PHONY: docker.build
docker.build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(ARTIFACT_REGISTRY_HOST)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(ARTIFACT_REGISTRY_HOST)/$(DOCKER_IMAGE):latest

.PHONY: docker.build.dev
docker.build.dev:
	docker build --target builder -t $(DOCKER_IMAGE):local .
	docker tag $(DOCKER_IMAGE):local $(DOCKER_IMAGE):latest

.PHONY: docker.push
docker.push:
	@echo "Pushing waypoint image to GAR..."
	docker push ${ARTIFACT_REGISTRY_HOST}/${DOCKER_IMAGE}:$(DOCKER_TAG)
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