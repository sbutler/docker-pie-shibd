DISTDIR      := $(PWD)/dist/

PROJECT      ?=publish
REPO_NAME    ?=$(PROJECT)/pie-shibd
REPO_URI     ?=$(shell aws ecr describe-repositories --repository-names $(REPO_NAME) --output text --query 'repositories[].repositoryUri' --region us-east-2)
REPO_URI_BAK ?=$(shell aws ecr describe-repositories --repository-names $(REPO_NAME) --output text --query 'repositories[].repositoryUri' --region us-east-1)
COMMIT_ID    :=$(shell git rev-parse --short HEAD)

.PHONY: clean ecr-login image-build image-push-latest image-push-dev image-push-test image-push-prod

check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

clean:
	rm -fr -- .venv || :
	rm -fr -- "$(DISTDIR)" || :

ecr-login:
	@:$(call check_defined, REPO_URI, Repository URI)
	_repo='$(REPO_URI)'; aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $${_repo%%/*}
	_repo='$(REPO_URI_BAK)'; [ -z $$_repo ] || aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $${_repo%%/*}

image-build:
	[ -e "$(DISTDIR)" ] || mkdir -p "$(DISTDIR)"
	docker pull public.ecr.aws/lts/ubuntu:22.04
	docker build -t $(REPO_NAME):latest --iidfile "$(DISTDIR)/config.image-id" .
	for _tag in "commit-$(COMMIT_ID)" latest-ubuntu latest-ubuntu22.04; do \
		docker tag $(REPO_NAME):latest $(REPO_NAME):$$_tag; \
	done

image-push-latest:
	@:$(call check_defined, REPO_URI, Repository URI)
	for _repo in "$(REPO_URI)" "$(REPO_URI_BAK)"; do \
		[ -n $$_repo ] || continue; \
		docker push $$_repo:latest; \
		sleep 10; \
		for _tag in "commit-$(COMMIT_ID)" latest-ubuntu latest-ubuntu22.04; do \
			docker tag $(REPO_NAME):latest $$_repo:$$_tag; \
			docker push $$_repo:$$_tag; \
			sleep 10; \
		done; \
	done

image-push-dev:
	@:$(call check_defined, REPO_URI, Repository URI)
	for _repo in "$(REPO_URI)" "$(REPO_URI_BAK)"; do \
		[ -n $$_repo ] || continue; \
		docker tag $(REPO_NAME):latest $$_repo:dev; \
		docker push $$_repo:dev; \
		sleep 10; \
	done

image-push-test:
	@:$(call check_defined, REPO_URI, Repository URI)
	for _repo in "$(REPO_URI)" "$(REPO_URI_BAK)"; do \
		[ -n $$_repo ] || continue; \
		docker tag $(REPO_NAME):latest $$_repo:test; \
		docker push $$_repo:test; \
		sleep 10; \
	done

image-push-prod:
	@:$(call check_defined, REPO_URI, Repository URI)
	for _repo in "$(REPO_URI)" "$(REPO_URI_BAK)"; do \
		[ -n $$_repo ] || continue; \
		docker tag $(REPO_NAME):latest $$_repo:prod; \
		docker push $$_repo:prod; \
		sleep 10; \
	done
