import re, urllib.request, os, sys
out = sys.argv[1]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36"
url = ("https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600"
       "&family=IBM+Plex+Sans+Hebrew:wght@300;400;500;600"
       
       "&family=Noto+Sans+Symbols:wght@400;500&family=Noto+Sans+Symbols+2&display=swap")
css = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA})).read().decode()
blocks = re.findall(r"/\* ([\w-]+) \*/\s*(@font-face \{.*?\})", css, re.S)
keep = {"latin","latin-ext","hebrew","symbols","math"}
res=[]; n=0
for subset, block in blocks:
    if subset not in keep: continue
    fam = re.search(r"font-family: '([^']+)'", block).group(1)
    w = re.search(r"font-weight: (\d+)", block).group(1)
    src = re.search(r"url\((.*?)\)", block).group(1)
    name = f"{fam.replace(' ','')}-{w}-{subset}.woff2"
    p = os.path.join(out, name)
    if not os.path.exists(p):
        open(p,"wb").write(urllib.request.urlopen(src).read()); n+=1
    res.append(block.replace(src, name))
open(os.path.join(out,"fonts.css"),"w").write("\n".join(res))
print(n, "files;", len(res), "faces")
