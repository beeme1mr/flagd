IMG ?= flagd:latest
PHONY: .docker-build .build .run .mockgen
PREFIX=/usr/local
ALL_GO_MOD_DIRS := $(shell find . -type f -name 'go.mod' -exec dirname {} \; | sort)

workspace-init:
	go work init
	$(foreach module, $(ALL_GO_MOD_DIRS), go work use $(module);)

workspace-update:
	$(foreach module, $(ALL_GO_MOD_DIRS), go work use $(module);)

guard-%:
	@ if [ "${${*}}" = "" ]; then \
        echo "Environment variable $* not set"; \
        exit 1; \
    fi
docker-build-flagd:
	docker buildx build --build-arg=VERSION="$$(git describe --tags --abbrev=0)" --build-arg=COMMIT="$$(git rev-parse --short HEAD)" --build-arg DATE="$$(date +%FT%TZ)" --platform="linux/arm64" -t ${IMG} -f flagd/build.Dockerfile .
docker-push-flagd:
	docker buildx build --push --build-arg=VERSION="$$(git describe --tags --abbrev=0)" --build-arg=COMMIT="$$(git rev-parse --short HEAD)" --build-arg DATE="$$(date +%FT%TZ)" --platform="linux/ppc64le,linux/s390x,linux/amd64,linux/arm64" -t ${IMG} -f flagd/build.Dockerfile .
build: # default to flagd
	make build-flagd
build-flagd:
	go build -ldflags "-X main.version=dev -X main.commit=$$(git rev-parse --short HEAD) -X main.date=$$(date +%FT%TZ)" -o ./bin/flagd ./flagd
build-kube-flagd-proxy:
	go build -ldflags "-X main.version=dev -X main.commit=$$(git rev-parse --short HEAD) -X main.date=$$(date +%FT%TZ)" -o ./bin/kube-flagd-proxy ./kube-flagd-proxy
test: # default to core
	make test-core
test-core:
	go test -race -covermode=atomic -cover -short ./core/pkg/... -coverprofile=core-coverage.out
flagd-integration-test: # dependent on ./bin/flagd start -f file:test-harness/symlink_testing-flags.json
	go test -cover ./flagd/tests/integration $(ARGS)
	cd test-harness; git restore testing-flags.json # reset testing-flags.json
run: # default to flagd
	make run-flagd
run-flagd:
	cd flagd; go run main.go start -f file:config/samples/example_flags.flagd.json
install:
	cp systemd/flagd.service /etc/systemd/system/flagd.service
	mkdir -p /etc/flagd
	cp systemd/flags.json /etc/flagd/flags.json
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp bin/flagd $(DESTDIR)$(PREFIX)/bin/flagd
	systemctl start flagd
uninstall:
	systemctl disable flagd
	systemctl stop flagd
	rm /etc/systemd/system/flagd.service
	rm -f $(DESTDIR)$(PREFIX)/bin/flagd
lint:
	go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(foreach module, $(ALL_GO_MOD_DIRS), ${GOPATH}/bin/golangci-lint run --deadline=3m --timeout=3m $(module)/...;)
install-mockgen:
	go install github.com/golang/mock/mockgen@v1.6.0
mockgen: install-mockgen
	mockgen -source=core/pkg/sync/http/http_sync.go -destination=core/pkg/sync/http/mock/http.go -package=syncmock
	mockgen -source=core/pkg/eval/ievaluator.go -destination=core/pkg/eval/mock/ievaluator.go -package=evalmock
generate-docs:
	cd flagd; go run ./cmd/doc/main.go
