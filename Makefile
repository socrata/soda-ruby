link_dir := $(shell mktemp -d /tmp/linkdoc.XXXX)

all:
	sass common/sass/common.sass:common/css/common.css
	-rm search.json
	jekyll build
	cp public/datasync/search.json search.json
	terminal-notifier -title "Jekyll" -message "Build complete."

test: all
	linklint -doc ${link_dir} -root public /@
	open ${link_dir}/index.html
