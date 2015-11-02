package main

// compile with: gox --output="../bin/file_engine_{{.OS}}_{{.Arch}}"

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
)

var (
	context Context
	items   ItemCollection
)

const (
	itemSpace         = 5
	maxSearchedItems  = 200
	maxDisplayedItems = 500
)

type Context struct {
	Query      string
	Columns    int
	Limit      int
	Source     string
	Dots       string
	DotsSize   int
	LowerRunes []rune
}

type FileItem struct {
	Index      int
	Name       string
	Noise      int
	SmallNoise int
	Pattern    string
	Runes      []rune
	LowerRunes []rune
}

func (item *FileItem) findSubsequence(offset int) (int, []int) {
	positions := make([]int, 0, len(item.LowerRunes))
	noise := 0

	for _, sl := range context.LowerRunes {
		pos := -1

		for i, l := range item.LowerRunes[offset:] {
			if l == sl {
				pos = i + offset
				break
			}
		}

		if pos == -1 {
			return -1, nil
		}

		if len(positions) > 0 {
			n := pos - positions[len(positions)-1]

			if n < 0 {
				n = -n
			}

			noise += n - 1
		}

		positions = append(positions, pos)
		offset = pos + 1
	}

	return noise, positions
}

func (item *FileItem) ComputeNoise() {
	noise := -1
	matched := ""

	if len(context.LowerRunes) == 1 {
		for i, l := range item.LowerRunes {
			if l == context.LowerRunes[0] {
				noise = i
				break
			}
		}

		if noise > -1 {
			matched = context.Query
		}
	} else {
		var positions []int
		offset := 0

		for len(context.LowerRunes) <= len(item.Runes)-offset {
			n, p := item.findSubsequence(offset)

			if n == -1 {
				break
			} else if noise == -1 || n < noise {
				noise, positions = n, p
				offset = positions[0] + 1
			} else {
				offset++
			}
		}

		if noise > -1 {
			matched = string(item.Runes[positions[0] : positions[len(positions)-1]+1])
			item.SmallNoise = 0

			if positions[0] != 0 {
				item.SmallNoise++
				r := item.Runes[positions[0]-1]

				if (r >= 48 && r <= 90) || r >= 97 {
					item.SmallNoise++
				}
			}

			if positions[len(positions)-1] != len(item.Runes)-1 {
				item.SmallNoise++
				r := item.Runes[positions[len(positions)-1]+1]

				if (r >= 48 && r <= 90) || r >= 97 {
					item.SmallNoise++
				}
			}
		}
	}

	if noise > -1 && matched != "" {
		item.Pattern = matched
	}

	item.Noise = noise
}

type ItemCollection []*FileItem

func (items *ItemCollection) Init() error {
	file, err := os.Open(context.Source)

	if err != nil {
		return err
	}

	defer file.Close()

	scanner := bufio.NewScanner(file)
	idx := 0

	for scanner.Scan() {
		text := scanner.Text()
		*items = append([]*FileItem(*items), &FileItem{
			Index:      idx,
			Name:       text,
			Runes:      []rune(text),
			LowerRunes: []rune(strings.ToLower(text)),
		})
		idx++
	}

	return scanner.Err()
}

func (items *ItemCollection) TrimByNoise() {
	results := make([]*FileItem, 0, maxSearchedItems)

	for _, item := range *items {
		item.ComputeNoise()

		if item.Noise == -1 {
			continue
		}

		if len(results) < maxSearchedItems {
			results = append(results, item)
		} else {
			maxIndex, maxNoise := -1, -1

			for i, r := range results {
				if r.Noise >= maxNoise {
					maxNoise = r.Noise
					maxIndex = i
				}
			}

			if maxNoise > item.Noise {
				results[maxIndex] = item
			}
		}
	}

	*items = ItemCollection(results)
}

type SortItems struct {
	items ItemCollection
}

func (s *SortItems) Len() int {
	return len(s.items)
}

func (s *SortItems) Swap(i, j int) {
	s.items[i], s.items[j] = s.items[j], s.items[i]
}

type SortByNoiseAndText struct{ SortItems }

func (s *SortByNoiseAndText) Less(i, j int) bool {
	if s.items[i].Noise < s.items[j].Noise {
		return false
	} else if s.items[i].Noise > s.items[j].Noise {
		return true
	} else if s.items[i].SmallNoise < s.items[j].SmallNoise {
		return false
	} else if s.items[i].SmallNoise > s.items[j].SmallNoise {
		return true
	} else if len(s.items[i].Runes) < len(s.items[j].Runes) {
		return false
	} else if len(s.items[i].Runes) > len(s.items[j].Runes) {
		return true
	} else {
		ss := sort.StringSlice{s.items[i].Name, s.items[j].Name}
		return ss.Less(0, 1)
	}
}

type SortByText struct{ SortItems }

func (s *SortByText) Less(i, j int) bool {
	ss := sort.StringSlice{s.items[i].Name, s.items[j].Name}
	return ss.Less(0, 1)
}

func Init(input *os.File) error {
	var err error
	var line []byte

	r := bufio.NewReader(input)

	if line, _, err = r.ReadLine(); err != nil {
		return err
	}

	if err = json.Unmarshal(line, &context); err != nil {
		return err
	}

	context.LowerRunes = []rune(strings.ToLower(context.Query))

	return items.Init()
}

func PrepareContent() ([]string, []string, string, []string) {
	if context.Query != "" {
		items.TrimByNoise()
		sort.Sort(&SortByNoiseAndText{SortItems{items}})
	} else {
		if len(items) > maxDisplayedItems {
			items = items[0:maxDisplayedItems]
		}

		sort.Sort(&SortByText{SortItems{items}})
	}

	if context.Limit > 0 && context.Limit < len(items) {
		items = items[len(items)-context.Limit : len(items)]
	}

	content := make([]string, len(items))
	indices := make([]string, len(items))

	uniqPatterns := make(map[string]bool)

	for i, item := range items {
		line := make([]rune, context.Columns)

		line[0] = ' '
		line[1] = ' '

		pos := 2

		if len(item.Runes)+itemSpace > context.Columns {
			for _, r := range []rune(context.Dots) {
				line[pos] = r
				pos++
			}

			for _, r := range item.Runes[len(item.Runes)-context.Columns+itemSpace+context.DotsSize:] {
				line[pos] = r
				pos++
			}
		} else {
			for _, r := range item.Runes {
				line[pos] = r
				pos++
			}
		}

		for pos < context.Columns {
			line[pos] = ' '
			pos++
		}

		content[i] = string(line)
		indices[i] = strconv.Itoa(item.Index)

		if len(item.Pattern) > 0 {
			uniqPatterns[item.Pattern] = true
		}
	}

	patterns, i := make([]string, len(uniqPatterns)), 0

	for p := range uniqPatterns {
		patterns[i] = fmt.Sprintf("%q", p)
		i++
	}

	return patterns, indices, strconv.Itoa(len(items)), content
}

func main() {
	if err := Init(os.Stdin); err != nil {
		log.Fatalf("%#v", err)
	}

	patterns, indices, size, content := PrepareContent()

	fmt.Printf("[%s]\n", strings.Join(patterns, ","))
	fmt.Printf("[%s]\n", strings.Join(indices, ","))
	fmt.Println(size)

	for _, line := range content {
		fmt.Println(line)
	}
}
