package pkg

import (
	"log"
	"os"
	"os/exec"
	"updategen/util"
)

//"k8s.io/apimachinery/pkg/util/yaml"

func GenerateFromYaml(tag string) error {
	assets, err := util.GetRepoAssetsList(RancherOrg, OctopusRepo, tag)
	if err != nil {
		return err
	}
	adaptorAssets, err := util.GetAdaptorAssetsData(RancherOrg, OctopusRepo, assets)
	if err != nil {
		return err
	}

	workDir := "workdir"

	_, err = os.Stat(workDir)
	if err != nil && os.IsNotExist(err) {
		if err = os.Mkdir(workDir, 0777); err != nil {
			return err
		}
	} else if err != nil && !os.IsNotExist(err) {
		return err
	} else {
		if err = os.RemoveAll(workDir); err != nil {
			return err
		}
		if err = os.Mkdir(workDir, 0777); err != nil {
			return err
		}
	}

	cmd := exec.Command("./script/octopus_template_update.sh", workDir)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return err
	}

	for name, data := range adaptorAssets {
		fileName := workDir + "/" + name + "_all_in_one.yaml"
		file, err := os.OpenFile(fileName, os.O_CREATE|os.O_RDWR, 0777)
		if err != nil {
			return err
		}
		if _, err := file.Write(data); err != nil {
			file.Close()
			return err
		}
		file.Close()
		cmd := exec.Command("./script/octopus_adaptor_template_update.sh", workDir, name, tag)
		out, err := cmd.CombinedOutput()
		if err != nil {
			log.Println(string(out))
			return err
		}
	}

	cmd = exec.Command("./script/octopus_ui_template_update.sh", workDir, tag)
	out, err = cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return err
	}

	return nil
}

func UpdateAndPushChart(workDir string) error {
	cmd := exec.Command("./script/update_push_chart.sh", workDir)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return err
	}
	return nil
}
