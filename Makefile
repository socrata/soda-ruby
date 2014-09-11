link_dir := $(shell mktemp -d /tmp/linkdoc.XXXX)

all:
	-rm search.json
	-rm related.json
	jekyll build
	-cp `find public -name search.json` search.json
	-cp `find public -name related.json` related.json
	-git add search.json related.json
	-terminal-notifier -title "Jekyll" -message "Build complete."

test: all
	linklint -doc ${link_dir} -root public /@
	open ${link_dir}/index.html
