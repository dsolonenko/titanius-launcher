package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
)

type Platforms struct {
	Platforms []Platform `json:"platformList"`
}

type Platform struct {
	FileName  string `json:"filename"`
	Name      string `json:"platformName"`
	ShortName string `json:"platformShortname"`
}

type Players struct {
	Player []Player `json:"playerList"`
}

type Player struct {
	Name                        string `json:"name"`
	Description                 string `json:"description"`
	AcceptedFilenameRegex       string `json:"acceptedFilenameRegex"`
	AmStartArguments            string `json:"amStartArguments"`
	KillPackageProcesses        bool   `json:"killPackageProcesses"`
	KillPackageProcessesWarning bool   `json:"killPackageProcessesWarning"`
	Extra                       string `json:"extra"`
}

type Emulator struct {
	Id     string `json:"id"`
	Name   string `json:"name"`
	Intent Intent `json:"intent"`
}

type Intent struct {
	Component string            `json:"component"`
	Action    string            `json:"action,omitempty"`
	Data      string            `json:"data,omitempty"`
	Args      map[string]string `json:"args,omitempty"`
	Flags     []string          `json:"flags,omitempty"`
}

type System struct {
	Id        string     `json:"id"`
	Name      string     `json:"name"`
	BigLogo   string     `json:"bigLogo,omitempty"`
	SmallLogo string     `json:"smallLogo,omitempty"`
	Folders   []string   `json:"folders,omitempty"`
	Emulators []Emulator `json:"emulators"`
}

type Systems struct {
	Systems []System `json:"systems"`
}

var imageNameOverrides = map[string]string{
	"3DO":                    "3DO_Interactive_Multiplayer",
	"Atomiswave":             "Sammy_Atomiswave",
	"CP_System_I":            "Capcom_Play_System",
	"CP_System_II":           "Capcom_Play_System_II",
	"CP_System_III":          "Capcom_Play_System_III",
	"DOS":                    "MS-DOS",
	"Dreamcast":              "Sega_Dreamcast",
	"Famicom_Disk_System":    "Nintendo_Famicom_Disk_System",
	"Arcade_(FinalBurn_Neo)": "Final_Burn_Neo",
	"Game \u0026 Watch":      "Nintendo_Game___Watch",
	"Game_Boy":               "Nintendo_Game_Boy",
	"Game_Boy_Advance":       "Nintendo_Game_Boy_Advance",
	"Game_Boy_Color":         "Nintendo_Game_Boy_Color",
	"GameCube":               "Nintendo_GameCube",
	"Intellivision":          "Mattel_Intellivision",
	"Arcade_(MAME)":          "MAME",
	"MSX":                    "Microsoft_MSX",
	"Neo_Geo":                "SNK_Neo_Geo",
	"Neo_Geo_CD":             "SNK_Neo_Geo_CD",
	"NeoGeo_Pocket":          "SNK_Neo_Geo_Pocket",
	"NeoGeo_Pocket_Color":    "SNK_Neo_Geo_Pocket_Color",
	"PC-88":                  "NEC_PC-8801",
	"PC-98":                  "NEC_PC-9801",
	"PC-FX":                  "NEC_PC-FX",
	"PICO-8":                 "Pico-8",
	"PlayStation_Portable":   "Sony_PSP",
	"Pokemon_Mini":           "Nintendo_Pokemon_Mini",
	"Sega_NAOMI":             "Sega_Naomi",
	"SuperGrafx":             "NEC_PC_Engine_SuperGrafx",
	"TurboGrafx-16":          "NEC_TurboGrafx-16",
	"TurboGrafx-CD":          "NEC_TurboGrafx-CD",
	"Vectrex":                "GCE_Vectrex",
	"Virtual_Boy":            "Nintendo_Virtual_Boy",
	"ZX_81":                  "Sinclair_ZX81",
	"ZX_Spectrum":            "Sinclair_ZX_Spectrum",
}

func main() {

	var index Platforms
	readJson("https://raw.githubusercontent.com/magneticchen/Daijishou/main/platforms/index.json", &index)
	fmt.Println(index)

	systems := Systems{
		Systems: []System{},
	}
	for _, platform := range index.Platforms {
		fmt.Println(platform.Name)
		var players Players
		readJson("https://raw.githubusercontent.com/magneticchen/Daijishou/main/platforms/"+platform.FileName, &players)
		imageName := strings.ReplaceAll(platform.Name, " ", "_")
		if override, ok := imageNameOverrides[platform.Name]; ok {
			imageName = override
		}
		system := System{
			Id:        platform.ShortName,
			Name:      platform.Name,
			BigLogo:   "https://ik.imagekit.io/ds2/titanius/dark_color/" + imageName + ".png",
			SmallLogo: "https://ik.imagekit.io/ds2/titanius/light_just_white/" + imageName + ".png",
			Folders:   []string{platform.ShortName},
			Emulators: []Emulator{},
		}
		for _, player := range players.Player {
			command := parseCommand(player.AmStartArguments)
			if strings.HasPrefix(command.Command, "com.retroarch.ra32/") || strings.HasPrefix(command.Command, "com.retroarch/") {
				continue
			}
			system.Emulators = append(system.Emulators, Emulator{
				Id:   playerNameToId(player.Name),
				Name: playerNameToName(player.Name),
				Intent: Intent{
					Component: command.Command,
					Action:    command.Action,
					Data:      command.Data,
					Args:      command.Options,
					Flags:     command.Flags,
				},
			})
		}
		systems.Systems = append(systems.Systems, system)
	}

	//write systems into pretty json file
	b, err := json.MarshalIndent(systems, "", "  ")
	if err != nil {
		fmt.Println("error:", err)
	}
	err = ioutil.WriteFile("systems.json", b, 0644)
	if err != nil {
		fmt.Println("error:", err)
	}
}

func playerNameToId(name string) string {
	id := strings.ReplaceAll(strings.ToLower(playerNameToName(name)), " ", "_")
	if strings.Contains(name, "RetroArch") {
		return "ra64/" + id
	}
	return id
}

func playerNameToName(name string) string {
	a := strings.Split(name, " - ")
	return a[len(a)-1]
}

func readJson(file string, v interface{}) {
	resp, err := http.Get(file)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	err = json.Unmarshal(body, v)
	if err != nil {
		log.Fatal(err)
	}
}

type CommandStruct struct {
	Command string
	Action  string
	Data    string
	Options map[string]string
	Flags   []string
}

type OptionStruct struct {
	Option string
	Value  string
}

func parseCommand(command string) CommandStruct {
	cmdStruct := CommandStruct{
		Command: "",
		Options: map[string]string{},
		Flags:   []string{},
	}
	cmdParts := strings.Fields(command)

	i := 0
	for i < len(cmdParts) {
		if strings.HasPrefix(cmdParts[i], "-e") || strings.HasPrefix(cmdParts[i], "--e") {
			option := cmdParts[i+1]
			value := cmdParts[i+2]
			if strings.HasPrefix(value, "-") {
				cmdStruct.Options[option] = "true"
				i += 2
			} else {
				cmdStruct.Options[option] = value
				i += 3
			}
		} else if strings.HasPrefix(cmdParts[i], "--") {
			cmdStruct.Flags = append(cmdStruct.Flags, cmdParts[i])
			i++
		} else if strings.HasPrefix(cmdParts[i], "-n") {
			cmdStruct.Command = cmdParts[i+1]
			i += 2
		} else if strings.HasPrefix(cmdParts[i], "-a") {
			cmdStruct.Action = cmdParts[i+1]
			i += 2
		} else if strings.HasPrefix(cmdParts[i], "-d") {
			cmdStruct.Data = cmdParts[i+1]
			i += 2
		} else {
			panic(cmdParts[i])
		}
	}

	return cmdStruct
}
