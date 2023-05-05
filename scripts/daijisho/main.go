package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

func main() {
	daijishoPlatforms, err := loadDaijishoPlatforms()
	if err != nil {
		fmt.Println("Error loading Daijisho platforms:", err)
		return
	}
	systems, err := loadMetadata()
	if err != nil {
		fmt.Println("Error loading metadata:", err)
		return
	}
	for _, p := range daijishoPlatforms.PlatformList {
		_, err := findSystem(systems, p.PlatformShortname)
		if err != nil {
			fmt.Printf("Error finding system for platform %s: %v\n", p.PlatformShortname, err)
			continue
		}
	}
}

func findSystem(systems SystemsJSON, platformShortname string) (System, error) {
	for _, system := range systems.Systems {
		if system.ID == platformShortname {
			return system, nil
		}
	}
	return System{}, fmt.Errorf("no system found for platform %s", platformShortname)
}

type Platform struct {
	Filename          string `json:"filename"`
	PlatformName      string `json:"platformName"`
	PlatformShortname string `json:"platformShortname"`
	RevisionNumber    int    `json:"revisionNumber"`
}

type PlatformIndex struct {
	BaseURI      string     `json:"baseUri"`
	PlatformList []Platform `json:"platformList"`
}

func loadDaijishoPlatforms() (PlatformIndex, error) {
	url := "https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/platforms/index.json"
	resp, err := http.Get(url)
	if err != nil {
		fmt.Printf("Error fetching JSON data: %v\n", err)
		return PlatformIndex{}, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading response body: %v\n", err)
		return PlatformIndex{}, err
	}

	var platformIndex PlatformIndex
	err = json.Unmarshal(body, &platformIndex)
	if err != nil {
		fmt.Printf("Error parsing JSON data: %v\n", err)
		return PlatformIndex{}, err
	}

	fmt.Printf("Base URI: %s\n", platformIndex.BaseURI)
	fmt.Println("Platform List:")
	for _, platform := range platformIndex.PlatformList {
		fmt.Printf("  Platform Name: %s\n", platform.PlatformName)
		fmt.Printf("  Filename: %s\n", platform.Filename)
		fmt.Printf("  Platform Shortname: %s\n", platform.PlatformShortname)
		fmt.Printf("  Revision Number: %d\n", platform.RevisionNumber)
		fmt.Println()
	}

	return platformIndex, nil
}

type Intent struct {
	Component string            `json:"component"`
	Args      map[string]string `json:"args"`
	Flags     []string          `json:"flags"`
}

type Emulator struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Intent Intent `json:"intent"`
}

type System struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	Logo      string     `json:"logo"`
	Folders   []string   `json:"folders"`
	Emulators []Emulator `json:"emulators"`
}

type SystemsJSON struct {
	Systems []System `json:"systems"`
}

func loadMetadata() (SystemsJSON, error) {
	jsonFile, err := os.Open("../../assets/metadata.json")
	if err != nil {
		fmt.Println("Error opening file:", err)
		return SystemsJSON{}, err
	}
	defer jsonFile.Close()

	bytes, err := ioutil.ReadAll(jsonFile)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return SystemsJSON{}, err
	}

	var systemsJSON SystemsJSON
	err = json.Unmarshal(bytes, &systemsJSON)
	if err != nil {
		fmt.Println("Error unmarshalling JSON:", err)
		return SystemsJSON{}, err
	}

	fmt.Println(systemsJSON)

	return systemsJSON, nil
}
