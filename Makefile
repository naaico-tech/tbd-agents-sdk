.PHONY: test-python build-python typecheck-typescript test-typescript build-typescript flutter-analyze flutter-test flutter-package validate clean

test-python:
	cd packages/python && python3 -m pytest

build-python:
	cd packages/python && python3 -m build

typecheck-typescript:
	cd packages/typescript && ([ -d node_modules ] || npm ci) && npm run typecheck

test-typescript:
	cd packages/typescript && ([ -d node_modules ] || npm ci) && npm test

build-typescript:
	cd packages/typescript && ([ -d node_modules ] || npm ci) && npm run build

flutter-analyze:
	cd packages/flutter && dart pub get && dart analyze

flutter-test:
	cd packages/flutter && dart test

flutter-package:
	cd packages/flutter && dart pub publish --dry-run

validate: test-python build-python typecheck-typescript test-typescript build-typescript flutter-analyze flutter-test flutter-package

clean:
	rm -rf packages/python/dist packages/python/.pytest_cache packages/typescript/dist packages/flutter/dist packages/flutter/.dart_tool packages/flutter/pubspec.lock
