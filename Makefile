SHELL := /bin/bash

.PHONY: check syntax safety render-public selftest package tree

check: syntax safety render-public selftest

syntax:
	./tools/syntax-check.sh

safety:
	./tools/public-safety-scan.sh

render-public:
	rm -rf /tmp/vmtl-rendered
	./tools/render-configs.py --public-only --output /tmp/vmtl-rendered
	./tools/validate-rendered-configs.py /tmp/vmtl-rendered

selftest:
	./tools/selftest.sh

package:
	./tools/build-release.sh

tree:
	find . -maxdepth 5 -type f -not -path './.git/*' -not -path './build/*' | sort
