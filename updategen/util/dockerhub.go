package util

import (
	"errors"
	"log"
	"os"

	"github.com/heroku/docker-registry-client/registry"
)

const (
	url      = "https://registry-1.docker.io/"
	username = "" // anonymous
	password = "" // anonymous
)

var (
	hub *registry.Registry
)

func init() {
	var err error
	hub, err = registry.New(url, username, password)
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}
}

func GetDockerImageLatestTag(repository string) (string, error) {
	tagList, err := hub.Tags(repository)
	if err != nil {
		return "", err
	}
	if len(tagList) < 1 {
		return "", errors.New("docker repository no tag")
	}

	return tagList[len(tagList)-1], nil
}

func IsDockerImageTagExist(repository string, tag string) (bool, error) {
	tagList, err := hub.Tags(repository)
	if err != nil {
		return false, err
	}
	for _, t := range tagList {
		if t == tag {
			return true, nil
		}
	}
	return false, nil
}
