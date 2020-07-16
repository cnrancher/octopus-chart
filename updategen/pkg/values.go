package pkg

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"updategen/util"

	"github.com/go-yaml/yaml"
	version "github.com/hashicorp/go-version"
)

const (
	RancherOrg    = "cnrancher"
	OctopusRepo   = "octopus"
	EdgeApiRepo   = "edge-api-server"
	AdaptorBle    = "octopus-adaptor-ble"
	AdaptorModbus = "octopus-adaptor-modbus"
	AdaptorOpcua  = "octopus-adaptor-opcua"
)

type Image struct {
	Repository string `json:"repository"`
	Tag        string `json:"tag"`
	PullPolicy string `json:"pullPolicy"`
}

type AdaptorBucket struct {
	Enabled bool  `json:"enabled"`
	Image   Image `json:"image"`
}

func UpdateValuesYaml(valuesFile string) (string, error) {
	octopusTag, err := getRepoLatestTag(RancherOrg, OctopusRepo)
	if err != nil {
		return octopusTag, err
	}
	//edgeApiTag,err := getRepoLatestTag(RancherOrg, EdgeApiRepo)
	edgeAPITag := "master"

	octopusImage := RancherOrg + "/" + OctopusRepo
	edgeAPIImage := RancherOrg + "/" + EdgeApiRepo

	imageExist, err := util.IsDockerImageTagExist(octopusImage, octopusTag)
	if err != nil {
		return octopusTag, err
	}
	if !imageExist {
		return octopusTag, fmt.Errorf("octopus image tag %s not found", octopusTag)
	}
	imageExist, err = util.IsDockerImageTagExist(edgeAPIImage, edgeAPITag)
	if err != nil {
		return octopusTag, err
	}
	if !imageExist {
		return octopusTag, fmt.Errorf("edge-api-server image tag %s not found", edgeAPITag)
	}

	adaptorTagMap, err := getAdaptorAndTag(octopusTag)
	if err != nil {
		return octopusTag, err
	}

	if err = util.UpdateValuesYamlUsePath(valuesFile, "octopus.image.tag", octopusTag); err != nil {
		return octopusTag, err
	}
	if err = util.UpdateValuesYamlUsePath(valuesFile, "octopus-ui.image.tag", edgeAPITag); err != nil {
		return octopusTag, err
	}

	for name, tag := range adaptorTagMap {
		path := name + "-adaptor" + ".image.tag"
		oldTag, err := util.ReadYamlValueUsePath(valuesFile, "0", path)
		if err != nil {
			return octopusTag, err
		}
		if oldTag == "" {
			log.Printf("values add new adaptor :%s", name)
			if err = addNewAdaptorBucket(valuesFile, name, tag, "Always"); err != nil {
				return octopusTag, err
			}
			continue
		}
		if oldTag != "master" && tag != "master" {
			oldVersion, err := version.NewVersion(oldTag)
			if err != nil {
				return octopusTag, err
			}
			newVersion, err := version.NewVersion(tag)
			if err != nil {
				return octopusTag, err
			}
			if oldVersion.LessThan(newVersion) {
				util.UpdateValuesYamlUsePath(valuesFile, path, tag)
			}
		} else {
			util.UpdateValuesYamlUsePath(valuesFile, path, tag)
		}
	}

	return octopusTag, nil
}

func getRepoLatestTag(org, repo string) (string, error) {
	tag, err := util.GetRepoLatestReleaseTag(org, repo)
	if err != nil {
		if !util.IsNotFoundError(err) {
			return "", err
		} else {
			if tag, err = util.GetRepoLatestTag(org, repo); err != nil {
				return "", err
			}
		}
	}
	return tag, nil
}

func getAdaptorAndTag(octopusTag string) (map[string]string, error) {
	adaptorTagMap := make(map[string]string)
	assets, err := util.GetRepoAssetsList(RancherOrg, OctopusRepo, octopusTag)
	if err != nil {
		return nil, err
	}
	adaptorDataMap, err := util.GetAdaptorAssetsData(RancherOrg, OctopusRepo, assets)
	if err != nil {
		return nil, err
	}

	getTagFromYamlData := func(data []byte, name string) (string, error) {
		tmpfile, err := ioutil.TempFile("", name+"_tmp.yaml")
		if err != nil {
			return "", err
		}
		defer tmpfile.Close()
		defer os.Remove(tmpfile.Name())
		if _, err := tmpfile.Write(data); err != nil {
			return "", err
		}
		value, err := util.ReadYamlValueUsePath(tmpfile.Name(), "*", "spec.template.spec.containers[0].image")
		if err != nil {
			return "", err
		}
		tmp := strings.Split(value, ":")
		if len(tmp) < 2 {
			return "", errors.New("adaptor image tag split error")
		}
		return tmp[1], nil
	}

	for name, data := range adaptorDataMap {
		tag, err := getTagFromYamlData(data, name)
		if err != nil {
			return nil, err
		}
		adaptorTagMap[name] = tag
	}

	return adaptorTagMap, nil
}

func addNewAdaptorBucket(valuesFile, adaptorName, tag, pullPolicy string) error {
	newAdaptorBucket := &AdaptorBucket{
		Enabled: true,
		Image: Image{
			Repository: "cnrancher/octopus-adaptor-" + adaptorName,
			Tag:        tag,
			PullPolicy: pullPolicy,
		},
	}
	blockMap := make(map[string]*AdaptorBucket)
	fieldName := adaptorName + "-adaptor"
	blockMap[fieldName] = newAdaptorBucket
	data, err := yaml.Marshal(blockMap)
	if err != nil {
		return err
	}
	tmpFileName := adaptorName + "_tmp_bucket.yaml"
	file, err := ioutil.TempFile("", tmpFileName)
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	if _, err = file.Write(data); err != nil {
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	return util.MargeYaml(valuesFile, file.Name())
}
