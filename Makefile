.PHONY: test-python build-python typecheck-typescript test-typescript build-typescript validate clean

test-python:
	cd packages/python && python3 -m pytest

build-python:
	cd packages/python && python3 -m build

typecheck-typescript:
	cd packages/typescript && npm run typecheck

test-typescript:
	cd packages/typescript && npm test

build-typescript:
	cd packages/typescript && npm run build

validate: test-python build-python typecheck-typescript test-typescript build-typescript

clean:
	rm -rf packages/python/dist packages/python/.pytest_cache packages/typescript/dist
