package pkg

import (
	"io/ioutil"
	"log"
	"os"
	"strings"
	"updategen/util"

	"github.com/go-yaml/yaml"
)

type DependentBucket struct {
	Name      string   `json:"name"`
	Version   string   `json:"version"`
	Condition string   `json:"condition"`
	Tags      []string `json:"tags"`
	Enabled   bool     `json:"enabled"`
}

func UpdateChartYaml(chartFile string) error {
	if err := updateAdaptorDependent(chartFile); err != nil {
		return err
	}
	return nil
}

func getAdaptorList(octopusTag string) ([]string, error) {
	assets, err := util.GetRepoAssetsList(RancherOrg, OctopusRepo, octopusTag)
	if err != nil {
		return nil, err
	}
	var list []string
	for _, as := range assets {
		if !strings.HasPrefix(*as.Name, "octopus_adaptor_") {
			continue
		}
		tmp := strings.TrimPrefix(*as.Name, "octopus_adaptor_")
		adaptorName := strings.TrimSuffix(tmp, "_all_in_one.yaml")
		list = append(list, adaptorName)
	}
	return list, nil
}

func updateAdaptorDependent(chartFile string) error {
	adaptorList, err := getAdaptorList("v0.0.3")
	if err != nil {
		return err
	}
	margeBucket := func(adaptorName string) error {
		var bucket DependentBucket
		bucket.Name = adaptorName + "-adaptor"
		bucket.Condition = bucket.Name + ".enabled"
		bucket.Enabled = true
		bucket.Version = "0.1.0"
		bucket.Tags = append(bucket.Tags, "octopus-adaptor")
		dependenciesBlock := make(map[string][]DependentBucket)
		dependenciesBlock["dependencies"] = append(dependenciesBlock["dependencies"], bucket)
		data, err := yaml.Marshal(&dependenciesBlock)
		if err != nil {
			return err
		}
		log.Println(string(data))
		tmpFile, err := ioutil.TempFile("", adaptorName+"tmp_dp.yaml")
		if err != nil {
			return err
		}
		defer tmpFile.Close()
		defer os.Remove(tmpFile.Name())
		if _, err := tmpFile.Write(data); err != nil {
			return err
		}

		if err := util.MargeYaml(chartFile, tmpFile.Name()); err != nil {
			return err
		}
		return nil
	}
	value, err := util.ReadYamlValueUsePath(chartFile, "*", "dependencies[*].name")
	if err != nil {
		return err
	}
	existDenpend := strings.Split(value, "\n")
	for _, adaptorName := range adaptorList {
		exist := false
		for _, ed := range existDenpend {
			if ed == adaptorName+"-adaptor" {
				exist = true
				break
			}
		}
		if exist {
			continue
		}
		if err := margeBucket(adaptorName); err != nil {
			return err
		}
	}
	return nil
}
