package main

import (
	"log"
	"os"
	"updategen/pkg"
)

func main() {
	tag, err := pkg.UpdateValuesYaml("../values.yaml")
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}
	if err := pkg.UpdateChartYaml("../Chart.yaml"); err != nil {
		log.Println(err)
		os.Exit(2)
	}
	if err := pkg.GenerateFromYaml(tag); err != nil {
		log.Println(err)
		os.Exit(3)
	}
	if err := pkg.UpdateAndPushChart("workdir"); err != nil {
		log.Println(err)
		os.Exit(4)
	}
}
