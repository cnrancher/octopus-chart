package util

import (
	"context"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/google/go-github/github"
)

var (
	gitUsername = strings.TrimSpace("parchk")
	gitPassword = strings.TrimSpace("565625207kbtHh!")
	// client     = github.NewClient(nil)
	tp = github.BasicAuthTransport{
		Username: gitUsername,
		Password: gitPassword,
	}
	client = github.NewClient(tp.Client())
)

func IsNotFoundError(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "404 Not Found")
}

func GetRepoLatestReleaseTag(owner, repo string) (string, error) {
	release, _, err := client.Repositories.GetLatestRelease(context.Background(), owner, repo)
	if err != nil {
		return "", err
	}
	return *release.TagName, nil
}

func GetRepoLatestTag(owner, repo string) (string, error) {
	repoList, _, err := client.Repositories.ListTags(context.Background(), owner, repo, &github.ListOptions{})
	if err != nil {
		return "", err
	}
	if len(repoList) < 1 {
		return "", errors.New("repo no tag")
	}

	return *repoList[0].Name, nil
}

func GetRepoAssetsList(owner, repo, tag string) ([]*github.ReleaseAsset, error) {
	rp, _, err := client.Repositories.GetReleaseByTag(context.Background(), owner, repo, tag)
	if err != nil {
		return nil, err
	}
	assets, _, err := client.Repositories.ListReleaseAssets(context.Background(), owner, repo, *rp.ID, &github.ListOptions{})
	if err != nil {
		return nil, err
	}
	return assets, nil
}

func GetAdaptorAssetsData(org, repo string, assets []*github.ReleaseAsset) (map[string][]byte, error) {
	adaptorMap := make(map[string][]byte)
	for _, as := range assets {
		if !strings.HasPrefix(*as.Name, "octopus_adaptor_") {
			continue
		}
		tmp := strings.TrimPrefix(*as.Name, "octopus_adaptor_")
		adaptorName := strings.TrimSuffix(tmp, "_all_in_one.yaml")

		data, err := GetAssetFileData(org, repo, as)
		if err != nil {
			return adaptorMap, err
		}

		adaptorMap[adaptorName] = data
	}
	return adaptorMap, nil
}

func GetOctopusAssets(org, repo string, assets []*github.ReleaseAsset) ([]byte, error) {
	for _, as := range assets {
		if *as.Name != "octopus_all_in_one.yaml" {
			continue
		}
		data, err := GetAssetFileData(org, repo, as)
		if err != nil {
			return nil, err
		}

		return data, nil
	}
	return nil, errors.New("octopus all in one assets not found")
}

func GetAssetFileData(owner, repo string, asset *github.ReleaseAsset) ([]byte, error) {
	req, err := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/repos/%s/%s/releases/assets/%d", owner, repo, *asset.ID), nil)
	if err != nil {
		return nil, err
	}
	req.SetBasicAuth(gitUsername, gitPassword)
	req.Header.Set("Accept", "application/octet-stream")

	cli := &http.Client{}
	var loc string
	cli.CheckRedirect = func(req *http.Request, via []*http.Request) error {
		loc = req.URL.String()
		return errors.New("disable redirect")
	}
	resp, err := cli.Do(req)
	if err != nil {
		if !strings.Contains(err.Error(), "disable redirect") {
			return nil, err
		}
		if loc != "" {
			realDownload := func(c *http.Client) ([]byte, error) {
				reqDownload, err := http.NewRequest("GET", loc, nil)
				for _, cookies := range resp.Cookies() {
					reqDownload.AddCookie(cookies)
				}
				respDownload, err := c.Do(reqDownload)
				if err != nil {
					return nil, err
				}
				defer respDownload.Body.Close()
				body, err := ioutil.ReadAll(respDownload.Body)
				if err != nil {
					return nil, err
				}
				return body, nil
			}

			fileData, err := realDownload(cli)
			if err != nil {
				return nil, err
			}

			return fileData, nil
		}
		return nil, errors.New("redirect url empty")
	}
	resp.Body.Close()
	return nil, errors.New("redirect error")
}
