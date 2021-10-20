repository = eu.gcr.io/ingka-ilo-ct-automation
app = mocked-app

default:

build:
	docker build -f $(app).Dockerfile -t $(repository)/$(app):latest .
	docker build -f $(app)-preinstall.Dockerfile -t $(repository)/$(app)-preinstall:latest .
	docker build -f $(app)-postinstall.Dockerfile -t $(repository)/$(app)-postinstall:latest .
ge