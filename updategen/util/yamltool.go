package util

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

func UpdateValuesYamlUsePath(fileName string, path string, value string) error {
	cmd := exec.Command("yq", "w", "-i", fileName, path, value)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return err
	}
	return nil
}

func UpdateValueFromDataUsePath(data []byte, path string, value string) ([]byte, error) {
	cmd := exec.Command("yq", "w", "-", path, value)
	r := bytes.NewReader(data)
	cmd.Stdin = r
	out, err := cmd.CombinedOutput()
	if err != nil {
		return out, err
	}
	return out, nil
}

func ReadYamlValueUsePath(fileName string, dotIndex string, path string) (string, error) {
	cmd := exec.Command("yq", "r", fmt.Sprintf("-d%s", dotIndex), fileName, path)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return "", err
	}
	v := strings.TrimSpace(string(out))
	return v, nil
}

func ReadYamlFromDataUsePath(data []byte, dotIndex string, path string) (string, error) {
	cmd := exec.Command("yq", "r", fmt.Sprintf("-d%s", dotIndex), "-", path)
	r := bytes.NewReader(data)
	cmd.Stdin = r
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return "", err
	}
	v := strings.TrimSpace(string(out))
	return v, nil
}

func MargeYaml(fileName string, other string) error {
	cmd := exec.Command("yq", "m", "-i", "-a", fileName, other)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println(string(out))
		return err
	}
	return nil
}

func CreateYamlUsePath(path string, value string) ([]byte, error) {
	cmd := exec.Command("yq", "n", path, value)
	return cmd.CombinedOutput()
}

func SplitYamlFile(fileName string) ([][]byte, error) {
	file, err := os.OpenFile(fileName, os.O_RDONLY, 0755)
	if err != nil {
		return nil, err
	}
	reader := bufio.NewReader(file)
	var result [][]byte
	var blockData []byte
	var blockCount int
	for {
		line, isPrefix, err := reader.ReadLine()
		if err != nil && err != io.EOF {
			return nil, err
		}
		if err == io.EOF {
			result = append(result, blockData)
			blockCount++
			blockData = blockData[:0:0]
			break
		}
		if strings.Contains(string(line), "---") {
			result = append(result, blockData)
			blockCount++
			blockData = blockData[:0:0]
			continue
		}
		blockData = append(blockData, line...)
		if !isPrefix {
			blockData = append(blockData, '\n')
		}
	}
	return result, nil
}

func GetTemplateMetaData([]byte, error) ([]byte, error) {
	return nil, nil
}
