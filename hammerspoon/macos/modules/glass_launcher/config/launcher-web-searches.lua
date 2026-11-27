-- Type a keyword followed by a space and the search terms.
return {
    { keyword = "g", name = "Google", url = "https://www.google.com/search?q={query}", icon = "fallback-icons/google.png", fallback = true },
    { keyword = "gh", name = "Github", url = "https://github.com/search?q={query}", icon = "fallback-icons/github.png", fallback = true },
    { keyword = "b", name = "Bilibili", url = "https://search.bilibili.com/all?keyword={query}", icon = "fallback-icons/bilibili.png", fallback = true },
    { keyword = "img", name = "Google Images", url = "https://www.google.com/search?tbm=isch&q={query}", icon = "fallback-icons/images.png", fallback = true },
    { keyword = "yt", name = "YouTube", url = "https://www.youtube.com/results?search_query={query}", icon = "fallback-icons/youtube.png", fallback = true },
    { keyword = "maps", name = "Google Maps", url = "https://www.google.com/maps/search/?api=1&query={query}", icon = "fallback-icons/maps.png", fallback = true },
    { keyword = "ddg", name = "DuckDuckGo", url = "https://duckduckgo.com/?q={query}", icon = "fallback-icons/duckduckgo.png", fallback = true },
}
