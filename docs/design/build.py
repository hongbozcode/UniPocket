"""Synchronize the Markdown and offline HTML handbook from the project catalog."""
import argparse
import html
import json
import re
from os.path import relpath
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit, urlunsplit

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RESOURCES = HERE / 'resources'
MD = ROOT / 'docs/product/design.md'


def relative_url(path, base):
    parts = urlsplit(path)
    relative = Path(relpath(ROOT / parts.path, base)).as_posix()
    if parts.path.endswith('/'):
        relative += '/'
    return urlunsplit(('', '', relative, parts.query, parts.fragment))


def url(path):
    return quote(relative_url(path, HERE), safe='/#?=&')


def link(label, path):
    return f'[{label}]({relative_url(path, MD.parent).replace(" ", "%20")})'


def esc(value):
    return html.escape(str(value), quote=True)


def table(headers, rows):
    clean = lambda text: str(text).replace('|', '\\|').replace('\n', '<br>')
    return '\n'.join(['| ' + ' | '.join(headers) + ' |', '| ' + ' | '.join(['---'] * len(headers)) + ' |'] + ['| ' + ' | '.join(map(clean, row)) + ' |' for row in rows])


def collect():
    data = json.loads((HERE / 'catalog.json').read_text(encoding='utf-8'))
    tokens = re.findall(r'(--[\w-]+):\s*([^;]+);', (RESOURCES / 'tokens.css').read_text(encoding='utf-8'))
    data['tokens'] = [{'name': name, 'value': value.strip()} for name, value in tokens]
    data['assets'] = []
    material_names = {Path(m['path']).stem: m['name'] for m in data['materials']}
    for kind in ['icons', 'illustrations', 'materials']:
        for path in sorted((RESOURCES / kind).iterdir()):
            if path.suffix.lower() not in ['.svg', '.png']:
                continue
            data['assets'].append({'kind': kind, 'name': material_names.get(path.stem, data['labels'].get(path.stem, path.stem)), 'file': path.name, 'path': path.relative_to(ROOT).as_posix(), 'source': '内置生图' if path.suffix == '.png' else '项目内 SVG'})
    for ref in data['references']:
        ref['url'] = url(ref['path'])
    for page in data['pages']:
        page['shotPath'] = page['currentShot'] if page.get('currentShot') else 'docs/design/resources/screenshots/' + page['shot']
        page['shotLabel'] = '当前动效样板' if page.get('currentShot') else '历史应用样板'
        page['shotUrl'] = url(page['shotPath'])
        page['actionsLabel'] = '当前演示操作' if page.get('currentShot') else '历史样板曾演示的操作'
        if any(m['id'] == page['id'] for m in data['motions']):
            page['demoPath'] = 'docs/design/motion.html?tool=' + page['id'].removeprefix('tool-')
            page['demoUrl'] = url(page['demoPath'])
    return data


def markdown(data):
    refs = {item['id']: item for item in data['references']}
    counts = {kind: sum(a['kind'] == kind for a in data['assets']) for kind in ['icons', 'illustrations', 'materials']}
    lines = [
        '# UniPocket 视觉设计规范与资源索引',
        '',
        f"> 后续页面设计与资源使用的现行规范。更新日期：{data['updatedAt']}。本文件自动生成，维护源见文末说明。",
        '',
        f"阅读顺序：**效果图 → HTML 样板运行截图与交互说明 → 设计资源 → 设计规范**。可视化对照：{link('HTML 设计手册', 'docs/design/index.html')}。",
        '',
        '业务依据：[首版规格](../../.scratch/unipocket-v1/spec.md)；术语：[词汇表](../../GLOSSARY.md)。',
        '',
        '## 依据与使用流程',
        '',
        *['- ' + item for item in data['authority']],
        '',
        *[f'{i}. {item}' for i, item in enumerate(data['workflow'], 1)],
        '',
        '## 01 / 效果图',
        '',
        f"当前 {len(data['references'])} 张效果图覆盖 {len(data['pages'])} 个页面，组合图可对应多个页面。效果图与提示词见[资源目录](../design/resources/README.md)。",
        '',
        table(['当前稿', '用途与约束', '来源'], [[link(r['name'], r['path']), r['note'], link('提示词', r['prompt'])] for r in data['references']]),
        '',
        '## 02 / HTML 样板运行截图与交互说明',
        '',
        '六项随机工具提供当前独立演示；其余页面仅保留历史截图，原完整应用样板源码未纳入仓库。逻辑标识用于清单关联，不是页面锚点或应用路由。补充状态见[截图索引](../design/resources/screenshots/README.md)。',
        '',
        table(['页面', '当前效果图', '逻辑标识', '运行截图', '可运行入口', '页面约束'], [[p['name'], link('效果图', refs[p['ref']]['path']), '`' + p['id'] + '`', link(p['shotLabel'], p['shotPath']), link('打开演示', p['demoPath']) if p.get('demoPath') else '仅历史截图', p['rule']] for p in data['pages']]),
        '',
        '### 页面内容与待补状态',
        '',
        table(['页面', '内容顺序', '样板操作及来源', '应用待补设计'], [[p['name'], p['content'], p['actionsLabel'] + '：' + p['actions'], p['pending']] for p in data['pages']]),
        '',
        '历史样板操作仅作记录，当前仓库无法运行复核；应用待补设计列定位尚需展开的界面与状态，完整开发范围以首版规格为准。',
        '',
        '### 样板资料',
        '',
        '- 原应用样板截图的示例日期固定为 2026-10-23、学期第 8 周；课程、任务和名单均为演示数据。',
        f"- 六项随机工具的**动效源码**：{link('motion-demo.js', 'docs/design/motion-demo.js')} 实现动画时序、结果呈现与交互逻辑；{link('motion-demo.css', 'docs/design/motion-demo.css')} 定义场景布局、样式与三维表现。",
        f"- {link('motion.html', 'docs/design/motion.html')} 是加载上述 JS／CSS 的独立演示入口，HTML 手册的“播放动效”也复用同一套源码。理解具体实现时读取动效源码，确认实际效果时用浏览器打开演示；编辑与状态保留方式见{link('演示使用说明', 'docs/design/README.md')}。",
        '',
        '## 03 / 设计资源',
        '',
        f"共 {len(data['assets'])} 个独立素材：{counts['icons']} 个界面图标、{counts['illustrations']} 个插画、{counts['materials']} 个材质文件。按以下索引引用；效果图和截图另列。",
        '',
        '### 界面图标',
        '',
        f"独立 SVG：{link('图标目录', 'docs/design/resources/icons/')}。默认主蓝，使用时可按平台设置颜色；尺寸和描边要求见“图标与插画”。",
        '',
        table(['名称', '文件'], [[a['name'], link(a['file'], a['path'])] for a in data['assets'] if a['kind'] == 'icons']),
        '',
        '### 贴纸与场景插画',
        '',
        table(['名称', '文件', '来源'], [[a['name'], link(a['file'], a['path']), a['source']] for a in data['assets'] if a['kind'] == 'illustrations']),
        '',
        '口袋、签袋为透明 PNG，纸纹为可平铺 PNG，其余为项目内 SVG。die.svg 用于入口贴纸；六面结构见 HTML 动效参考。',
        '',
        '素材生成记录：' + '、'.join(link(p['name'], p['path']) for p in data.get('assetPrompts', [])) + '。',
        '',
        '### 通用材质',
        '',
        table(['素材', '文件', '样式', '用途'], [[m['name'], link(m['path'], 'docs/design/resources/materials/' + m['path']), '`.' + m['class'] + '`', m['use']] for m in data['materials']]),
        '',
        '### HTML 资源复用',
        '',
        *['- ' + item for item in data['htmlReuse']],
        '',
        '### 视觉参数与通用样式', '',
        table(['入口', '职责'], [[link('tokens.css', 'docs/design/resources/tokens.css'), '颜色、字体、间距、圆角与阴影'], [link('materials.css', 'docs/design/resources/materials.css'), '通用纸纹、撕边、胶带、横线与网格']]), '',
        '## 04 / 设计规范',
        ''
    ]
    for rule in data['rules']:
        lines += ['### ' + rule['title'], ''] + ['- ' + item for item in rule['items']] + ['']
    lines += [
        '### 视觉变量（从 tokens.css 自动提取）', '',
        '颜色、字体与尺寸参数读取独立资源库；HTML 单位的跨平台使用见“HTML 资源复用”。', '',
        table(['变量', '当前值'], [['`' + t['name'] + '`', '`' + t['value'] + '`'] for t in data['tokens']]), '',
        '### 随机工具 HTML 动效参考', '',
        data['motionScope'], '',
        *['- ' + item for item in data['motionRules']], '',
        *motion_markdown(data),
        f"演示使用方式见{link('维护说明', 'docs/design/README.md')}；运行证据与限制见{link('检查记录', 'docs/design/verification.md')}。", '',
        '### 更新与验收清单', '',
        *['- [ ] ' + item for item in data['checklist']], '',
        '资源清单、生成源与更新命令见[手册维护说明](../design/README.md)。', ''
    ]
    return '\n'.join(lines)


def motion_markdown(data):
    lines = []
    for motion in data['motions']:
        lines += [
            '#### ' + motion['page'], '',
            f"- **触发与时长：**{motion['trigger']}参考时长：{motion['duration']}。",
            '- **动作：**' + motion['path'],
            '- **完成条件：**' + motion['result'], ''
        ]
    return lines


def demo_button(page_id, data):
    if any(m['id'] == page_id for m in data['motions']):
        return f'<button data-demo="{page_id}">播放动效</button>'
    return ''


def html_content(data):
    refs = {r['id']: r for r in data['references']}
    figures = ''.join(f'''<article class="reference-card"><button class="image-button" data-zoom="{esc(r['url'])}" data-title="{esc(r['name'])}" aria-label="放大{esc(r['name'])}效果图"><img src="{esc(r['url'])}" alt="{esc(r['name'])}效果图" loading="lazy"></button><div class="card-copy"><span class="tag">当前稿</span><h3>{esc(r['name'])}</h3><p>{esc(r['note'])}</p><a href="{url(r['prompt'])}">查看生成提示词 ↗</a></div></article>''' for r in data['references'])
    pages = ''.join(f'''<article class="page-card" data-group="{esc(p['group'])}" data-search="{esc(p['name']+' '+p['content'])}"><button class="shot-button" data-compare="{p['id']}" aria-label="对照{p['name']}效果图与截图"><img src="{p['shotUrl']}" alt="{p['name']} {p['shotLabel']}截图" loading="lazy"></button><div class="page-copy"><span class="eyebrow">{esc(p['group'])} · {p['shotLabel']}</span><h3>{esc(p['name'])}</h3><code>{p['id']}</code><p>{esc(p['rule'])}</p><div class="page-links"><button data-compare="{p['id']}">图稿对照</button>{demo_button(p['id'], data)}</div></div></article>''' for p in data['pages'])
    assets = ''.join(f'''<a class="asset-card" data-kind="{a['kind']}" data-search="{esc(a['name']+' '+a['file'])}" href="{url(a['path'])}" download="{esc(a['file'])}" title="下载 {esc(a['file'])}"><span class="asset-canvas"><img src="{url(a['path'])}" alt="" loading="lazy"></span><strong>{esc(a['name'])}</strong><code>{esc(a['file'])}</code><small>{esc(a['source'])} · 下载 ↓</small></a>''' for a in data['assets'])
    rules = ''.join(f'''<article class="rule-card"><span class="rule-number">0{i+1}</span><h3>{esc(r['title'])}</h3><ul>{''.join('<li>'+esc(item)+'</li>' for item in r['items'])}</ul></article>''' for i, r in enumerate(data['rules']))
    colors = ''.join(f'''<button class="color-card" data-copy="{esc(t['value'])}" aria-label="复制 {esc(t['name'])} {esc(t['value'])}"><span style="background:{esc(t['value'])}"></span><strong>{esc(t['name'].replace('--color-',''))}</strong><code>{esc(t['value'])}</code></button>''' for t in data['tokens'] if t['name'].startswith('--color-'))
    motion_cards = []
    for motion in data['motions']:
        motion_cards.append(f'<article class="rule-card"><h3>{esc(motion["page"])}</h3><ul><li><strong>触发与时长：</strong>{esc(motion["trigger"])}参考时长：{esc(motion["duration"])}。</li><li><strong>动作：</strong>{esc(motion["path"])}</li><li><strong>完成条件：</strong>{esc(motion["result"])}</li></ul>{demo_button(motion['id'], data)}</article>')
    motion_content = '<div class="rule-card"><ul>' + ''.join('<li>' + esc(item) + '</li>' for item in data['motionRules']) + '</ul></div><div class="rule-grid">' + ''.join(motion_cards) + '</div>'
    payload = json.dumps({'pages': data['pages'], 'references': refs}, ensure_ascii=False).replace('<', '\\u003c')
    template = (HERE / 'handbook.template.html').read_text(encoding='utf-8')
    tokens = {t['name']: t['value'] for t in data['tokens']}
    radii = ''.join(f'<span style="border-radius:var({esc(name)})">{esc("胶囊" if name == "--radius-pill" else value.removesuffix("px"))}</span>' for name, value in tokens.items() if name.startswith('--radius-'))
    def items(key, ordered=False):
        tag = 'ol' if ordered else 'ul'
        return '<' + tag + '>' + ''.join('<li>' + esc(item) + '</li>' for item in data[key]) + '</' + tag + '>'
    replacements = {'REFERENCES':figures, 'PAGES':pages, 'ASSETS':assets, 'RULES':rules, 'COLORS':colors, 'MOTIONS':motion_content, 'DATA':payload, 'VERSION':esc(data['updatedAt']), 'ASSET_COUNT':str(len(data['assets'])), 'PAGE_COUNT':str(len(data['pages'])), 'REFERENCE_COUNT':str(len(data['references'])), 'AUTHORITY':items('authority'), 'WORKFLOW':items('workflow', True), 'CHECKLIST':items('checklist'), 'HTML_REUSE':items('htmlReuse'), 'MOTION_SCOPE':esc(data['motionScope'])}
    replacements.update({kind.upper() + '_COUNT': str(sum(a['kind'] == kind for a in data['assets'])) for kind in ['icons', 'illustrations', 'materials']})
    replacements.update({'SPACE_BASE': esc(tokens['--space-1']), 'PAGE_PADDING': esc(tokens['--space-5']), 'RADII': radii})
    for key, value in replacements.items():
        template = template.replace('{{'+key+'}}', value)
    return template


class LocalLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.targets = []
        self.ids = []

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ['href', 'src'] and value:
                self.targets.append(value)
            if name == 'id':
                self.ids.append(value)


def verify_links(outputs, data):
    documents = dict(outputs)
    project_docs = [*ROOT.glob('*.md'), *(ROOT / 'docs').rglob('*.md'), *(ROOT / '.scratch').rglob('*.md')]
    for file in project_docs:
        if file not in documents:
            documents[file] = file.read_text(encoding='utf-8')
    checked = 0
    for file, content in documents.items():
        if file.suffix == '.html':
            parsed = LocalLinks()
            parsed.feed(content)
            targets = parsed.targets
            if len(set(parsed.ids)) != len(parsed.ids):
                raise SystemExit('Duplicate HTML ids: ' + str(file))
        else:
            prose = re.sub(r'```.*?```', '', content, flags=re.S)
            targets = re.findall(r'\[[^\]]+\]\(([^)]+)\)', prose)
        for target in targets:
            target = urlsplit(html.unescape(target))
            if target.scheme or target.netloc:
                continue
            resolved = (file.parent / unquote(target.path)).resolve() if target.path else file
            if not resolved.exists():
                raise SystemExit(f'Broken link in {file.relative_to(ROOT)}: {target.path}')
            if file.suffix == '.html' and not target.path and target.fragment and target.fragment not in parsed.ids:
                raise SystemExit('Unknown anchor: ' + target.fragment)
            checked += 1
    return checked


def verify_paths(data):
    paths = [r[k] for r in data['references'] for k in ['path', 'prompt']]
    paths += [p[k] for p in data.get('assetPrompts', []) for k in ['path', 'asset']]
    paths += [p['shotPath'] for p in data['pages']]
    paths += [a['path'] for a in data['assets']]
    paths += ['docs/design/resources/tokens.css', 'docs/design/resources/materials.css', 'AGENTS.md']
    missing = [p for p in paths if not (ROOT / p).exists()]
    if missing:
        raise SystemExit('Missing resources: ' + ', '.join(missing))
    for kind in ['pages', 'references']:
        ids = [item['id'] for item in data[kind]]
        if not ids or len(ids) != len(set(ids)):
            raise SystemExit(f'Expected nonempty, unique {kind} ids')
    for p in data['pages']:
        if p['ref'] not in {r['id'] for r in data['references']}:
            raise SystemExit('Unknown reference: ' + p['ref'])
    return len(set(paths))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify local resources and generated documents without writing')
    args = parser.parse_args()
    data = collect()
    count = verify_paths(data)
    outputs = {MD: markdown(data), HERE / 'index.html': html_content(data)}
    links = verify_links(outputs, data)
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != content:
                raise SystemExit('Out of date: ' + str(path))
        else:
            path.write_text(content, encoding='utf-8')
    print(f'{"Checked" if args.check else "Built"}: {len(data["pages"])} pages, {len(data["references"])} references, {len(data["assets"])} assets; {count} local resource paths and {links} document links valid.')


if __name__ == '__main__':
    main()
