package main

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

type VimContext struct {
	CurrentListView   string
	SearchModeEnabled int
	SearchText        string
	SearchResonators  string
	Columns           int
	MaxHeight         int
	MaxSearchedItems  int
	MaxDisplayedItems int
	Dots              string
	Sizes             struct {
		IAV  int
		IM   int
		Dots int
	}
	SearchLowerRunes []rune
	ResonatorRunes   []rune
}

type Item struct {
	Index          int
	Text           string
	Indicators     string
	Noise          int
	Pattern        string
	TextRunes      []rune
	TextLowerRunes []rune
}

func NewContext(line []byte) (*VimContext, error) {
	var c VimContext
	var err error

	if err = json.Unmarshal(line, &c); err == nil {
		c.SearchLowerRunes = []rune(strings.ToLower(c.SearchText))
		c.ResonatorRunes = []rune(c.SearchResonators)
	}

	return &c, err
}

func NewItemsFromFile(r *bufio.Reader) ([]*Item, error) {
	path, _, err := r.ReadLine()

	if err != nil {
		return nil, err
	}

	file, err := os.Open(string(path))

	if err != nil {
		return nil, err
	}

	defer file.Close()

	scanner := bufio.NewScanner(file)
	idx := 0

	var items []*Item

	for scanner.Scan() {
		text := scanner.Text()
		items = append(items, &Item{
			Index:          idx,
			Text:           text,
			TextRunes:      []rune(text),
			TextLowerRunes: []rune(strings.ToLower(text)),
		})
		idx++
	}

	return items, scanner.Err()
}

func NewItemsFromInput(r *bufio.Reader) ([]*Item, error) {
	scanner := bufio.NewScanner(r)

	var items []*Item

	for scanner.Scan() {
		var item Item

		if err := json.Unmarshal(scanner.Bytes(), &item); err == nil {
			item.TextRunes = []rune(item.Text)
			item.TextLowerRunes = []rune(strings.ToLower(item.Text))
			items = append(items, &item)
		} else {
			return items, err
		}
	}

	return items, scanner.Err()
}

func ParseStdin() (*VimContext, []*Item, error) {
	r := bufio.NewReader(os.Stdin)
	line, _, err := r.ReadLine()

	if err != nil {
		return nil, nil, err
	}

	context, err := NewContext(line)

	if err != nil {
		return context, nil, err
	}

	var items []*Item

	if context.CurrentListView == "File" {
		items, err = NewItemsFromFile(r)
	} else {
		items, err = NewItemsFromInput(r)
	}

	return context, items, err
}

func findSubsequence(letters []rune, text []rune, offset int) (int, []int) {
	positions := make([]int, 0, len(text))
	noise := 0

	for _, l := range letters {
		pos := -1

		for i, t := range text[offset:] {
			if t == l {
				pos = i + offset
				break
			}
		}

		if pos == -1 {
			return -1, nil
		} else {
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
	}

	return noise, positions
}

func findLowestSearchNoise(context *VimContext, item *Item) (int, string) {
	noise := -1
	matched := ""

	if len(context.SearchLowerRunes) == 1 {
		for i, t := range item.TextLowerRunes {
			if t == context.SearchLowerRunes[0] {
				noise = i
				break
			}
		}

		if noise > -1 {
			matched = context.SearchText
		}
	} else {
		offset := 0

		for offset < len(item.TextRunes) {
			n, p := findSubsequence(context.SearchLowerRunes, item.TextLowerRunes, offset)

			if n == -1 {
				break
			} else if noise == -1 || n < noise {
				noise = n
				offset = p[0] + 1
				matched = string(item.TextRunes[p[0] : p[len(p)-1]+1])

				if len(context.ResonatorRunes) > 0 {
					if p[0] != 0 {
						noise++
						moreNoise := true

						for _, r := range context.ResonatorRunes {
							if r == item.TextRunes[p[0]-1] {
								moreNoise = false
								break
							}
						}

						if moreNoise {
							noise++
						}
					}

					if p[len(p)-1] != len(item.TextRunes)-1 {
						noise++
						moreNoise := true

						for _, r := range context.ResonatorRunes {
							if r == item.TextRunes[p[len(p)-1]+1] {
								moreNoise = false
								break
							}
						}

						if moreNoise {
							noise++
						}
					}
				}
			} else {
				offset++
			}
		}
	}

	pattern := ""

	if noise > -1 && matched != "" {
		pattern = matched
	}

	return noise, pattern
}

func ComputeLowestNoises(context *VimContext, items []*Item) []*Item {
	results := make([]*Item, 0, context.MaxSearchedItems)
	noises := make([]int, 0, context.MaxSearchedItems)
	count := 0

	for _, item := range items {
		noise, pattern := findLowestSearchNoise(context, item)

		if noise == -1 {
			continue
		} else {
			item.Noise = noise
			item.Pattern = pattern

			if count < context.MaxSearchedItems {
				count++
				results = append(results, item)
				noises = append(noises, noise)
			} else {
				maxNoise := -1
				maxIndex := -1

				for i, n := range noises {
					if n >= maxNoise {
						maxNoise = n
						maxIndex = i
					}
				}

				if maxNoise > noise {
					noises[maxIndex] = noise
					results[maxIndex] = item
				}
			}
		}
	}

	return results
}

type SortItems struct {
	items []*Item
}

func (s *SortItems) Len() int {
	return len(s.items)
}

func (s *SortItems) Swap(i, j int) {
	s.items[i], s.items[j] = s.items[j], s.items[i]
}

type SortByNoiseAndText struct {
	SortItems
}

func (s *SortByNoiseAndText) Less(i, j int) bool {
	if s.items[i].Noise < s.items[j].Noise {
		return false
	} else if s.items[i].Noise > s.items[j].Noise {
		return true
	} else if len(s.items[i].TextRunes) < len(s.items[j].TextRunes) {
		return false
	} else if len(s.items[i].TextRunes) > len(s.items[j].TextRunes) {
		return true
	} else {
		ss := sort.StringSlice{s.items[i].Text, s.items[j].Text}
		return ss.Less(0, 1)
	}
}

type SortByIndex struct {
	SortItems
}

func (s *SortByIndex) Less(i, j int) bool {
	return s.items[i].Index < s.items[j].Index
}

type SortByText struct {
	SortItems
}

func (s *SortByText) Less(i, j int) bool {
	ss := sort.StringSlice{s.items[i].Text, s.items[j].Text}
	return ss.Less(0, 1)
}

func PrepareContent(context *VimContext, items []*Item) ([]string, []string, string, []string) {
	itemSpace := 5

	if context.CurrentListView == "Bookmark" {
		itemSpace += context.Sizes.IAV
	} else if context.CurrentListView != "File" {
		itemSpace += context.Sizes.IAV + context.Sizes.IM
	}

	content := make([]string, 0, len(items))
	indices := make([]string, 0, len(items))
	patterns := make(map[string]bool)

	for _, item := range items {
		line := append(make([]rune, 0, context.Columns), ' ', ' ')

		if len(item.TextRunes)+itemSpace > context.Columns {
			line = append(line, []rune(context.Dots)...)
			line = append(line, item.TextRunes[len(item.TextRunes)-context.Columns+itemSpace+context.Sizes.Dots:]...)
		} else {
			line = append(line, item.TextRunes...)
		}

		if indicators := []rune(item.Indicators); len(indicators) > 0 {
			line = append(line, ' ')
			line = append(line, indicators...)
		}

		for len(line) < context.Columns {
			line = append(line, ' ')
		}

		content = append(content, string(line))

		if len(item.Pattern) > 0 {
			patterns[item.Pattern] = true
		}

		indices = append(indices, strconv.Itoa(item.Index))
	}

	patternKeys := make([]string, 0, len(patterns))

	for k := range patterns {
		patternKeys = append(patternKeys, fmt.Sprintf("%q", k))
	}

	return patternKeys, indices, strconv.Itoa(len(items)), content
}

func main() {
	context, items, err := ParseStdin()

	if err != nil {
		log.Fatalf("%#v", err)
	}

	if context.SearchText != "" {
		items = ComputeLowestNoises(context, items)
		sort.Sort(&SortByNoiseAndText{SortItems{items}})
	} else {
		if len(items) > context.MaxDisplayedItems {
			items = items[0:context.MaxDisplayedItems]
		}

		if context.CurrentListView == "Tab" {
			sort.Sort(&SortByIndex{SortItems{items}})
		} else {
			sort.Sort(&SortByText{SortItems{items}})
		}
	}

	if context.SearchModeEnabled == 1 {
		if len(items) > context.MaxHeight {
			items = items[len(items)-context.MaxHeight : len(items)]
		}
	}

	patterns, indices, size, content := PrepareContent(context, items)

	fmt.Printf("[%s]\n", strings.Join(patterns, ","))
	fmt.Printf("[%s]\n", strings.Join(indices, ","))
	fmt.Println(size)

	for _, line := range content {
		fmt.Println(line)
	}
}
