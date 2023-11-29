import os, re, json, requests

def get_wikifier_response(text, KEY, threshold=0.8, language='en'):
    url = f"http://www.wikifier.org/annotate-article?text={text}&lang={language}&userKey={KEY}&pageRankSqThreshold={threshold}"
    response = requests.get(url)
    return response.json()


def get_wikification(text_file_path, KEY):
    json_file_path = re.sub(r'\.txt$', '_wikifier_response.json', text_file_path)

    if os.path.exists(json_file_path):
        with open(json_file_path, 'r', encoding='utf-8') as cached_file:
            return json.load(cached_file)
    else:
        with open(text_file_path, 'r', encoding='utf-8') as text_file:
            text = text_file.read()
        wikifier_response = get_wikifier_response(text, KEY)
        with open(json_file_path, 'w', encoding='utf-8') as cached_file:
            json.dump(wikifier_response, cached_file, ensure_ascii=False, indent=2)
        return wikifier_response


def build_doc(wiki):
    words = wiki['words']
    spaces = wiki['spaces']
    document = ""
    
    # Ensure the lengths of spaces and words are the same
    min_len = min(len(spaces), len(words))
    
    for i in range(min_len):
        document += spaces[i] + words[i]

    # Add the remaining words if any
    document += "".join(words[min_len:])

    return document


def get_links(wiki):
    links = []
    for annotation in wiki['annotations']:
        for support in annotation['support']:
            ch_from = support['chFrom']
            ch_to = support['chTo']
            hyperlink = annotation['url']
            links.append((ch_from, ch_to, hyperlink))
    return links


def embed_link(doc, link):
    ch_from, ch_to, hyperlink = link
    embedded_doc = doc[:ch_from] + f'<a href="{hyperlink}">' + doc[ch_from:ch_to] + '</a>' + doc[ch_to:]
    return embedded_doc


def filter_longest_links(wiki):
    links = get_links(wiki)
    longest_links = {}
    for link in links:
        url = link[2]
        if url not in longest_links:
            longest_links[url] = link
        else:
            existing_link = longest_links[url]
            if link[1] - link[0] > existing_link[1] - existing_link[0]:
                longest_links[url] = link
    return sorted(longest_links.values())


def embed_links(wiki):
    doc = build_doc(wiki)
    links = get_links(wiki)
    longest_links = filter_longest_links(wiki)
    sorted_links = sorted(longest_links, key=lambda x: x[1], reverse=True)
    prev_from = float("Inf")
    for link in sorted_links:
        ch_from, ch_to, hyperlink = link
        if ch_to < prev_from or not sorted_links.index(link):
            doc = embed_link(doc, link)
            prev_from = ch_from
    return doc


