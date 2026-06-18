#!/usr/bin/env python3
"""
NinKing MBTI 报告 HTML 渲染器 — 读取 JSON 报告文档，生成可视化 HTML。

本文件只做数据 → HTML 模板替换，不含任何分析逻辑。

用法:
    python render_mbti_html.py --input reports/mbti_report_data_*.json
    python render_mbti_html.py                                   # 自动找最新 JSON
    python render_mbti_html.py --output myreport.html
"""
import json
import os
import sys
import glob

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPORTS_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..",
                 "docs", "ninking", "08-testing", "reports")
)


def find_latest_json():
    """在 reports/ 目录下找最新的 JSON 报告"""
    files = sorted(glob.glob(os.path.join(REPORTS_DIR, "mbti_report_data_*.json")))
    if not files:
        print("❌ 未找到 JSON 报告文件，请先运行 analyze_mbti_report.py")
        return None
    return files[-1]


def load_report_data(json_path):
    """加载 JSON 报告文档"""
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)


def render_html(report_data):
    """
    将报告数据渲染为自包含 HTML。
    本函数仅做数据 → 模板替换，不含分析逻辑。
    """
    results = report_data.get("results", [])
    findings = report_data.get("findings", [])
    inflation = report_data.get("inflation")
    suggestions = report_data.get("suggestions", [])
    at_pairs = report_data.get("at_pairs", [])
    timestamp = report_data.get("meta", {}).get("timestamp", "")

    results_json = json.dumps(results, ensure_ascii=False)
    findings_json = json.dumps(findings, ensure_ascii=False)
    inflation_json = json.dumps(inflation, ensure_ascii=False) if inflation else "null"
    suggestions_json = json.dumps(suggestions, ensure_ascii=False)
    at_json = json.dumps(at_pairs, ensure_ascii=False)

    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NinKing MBTI 32型 · 模拟测试报告 {timestamp}</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,"Microsoft YaHei","PingFang SC",sans-serif; background:#0f0f23; color:#e0e0e0; }}
.container {{ max-width:1100px; margin:0 auto; padding:24px 20px; }}
h1 {{ font-size:26px; color:#ffd700; }}
h2 {{ font-size:18px; color:#ffd700; margin:28px 0 12px; border-bottom:1px solid #2a2a5a; padding-bottom:6px; }}
h3 {{ font-size:15px; color:#ddd; margin:16px 0 8px; }}
.report-meta {{ font-size:13px; color:#888; margin:6px 0 20px; display:flex; gap:20px; flex-wrap:wrap; }}
.meta-tag {{ background:#1e1e3a; padding:2px 10px; border-radius:4px; }}
.findings {{ display:flex; flex-direction:column; gap:8px; margin:12px 0; }}
.finding {{ padding:12px 16px; border-radius:8px; border:1px solid #2a2a5a; display:flex; align-items:center; gap:10px; font-size:14px; line-height:1.5; }}
.finding .rating {{ font-size:20px; }}
.finding.normal {{ background:#0f2a0f; border-color:#1b5e20; }}
.finding.warning {{ background:#2a1f0f; border-color:#795548; }}
.finding.weak {{ background:#2a0f0f; border-color:#5e1b1b; }}
.finding.critical {{ background:#3a0f0f; border-color:#8b1a1a; }}
.finding.op {{ background:#1f0f2a; border-color:#6a1b8b; }}
.kpi-grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:12px; margin:16px 0; }}
.kpi-card {{ background:#16163a; border-radius:10px; padding:16px; border:1px solid #2a2a5a; }}
.kpi-card .kpi-label {{ font-size:11px; color:#888; text-transform:uppercase; }}
.kpi-card .kpi-value {{ font-size:28px; font-weight:700; margin:4px 0; }}
.kpi-card .kpi-sub {{ font-size:12px; color:#888; }}
table {{ width:100%; border-collapse:collapse; margin:12px 0 20px; font-size:13px; }}
th {{ background:#0f0f23; color:#ffd700; padding:8px 12px; text-align:center; border-bottom:2px solid #2a2a5a; }}
td {{ padding:8px 12px; text-align:center; border-bottom:1px solid #1e1e3a; }}
tr:hover td {{ background:#1a1a3a; }}
.bar-bg {{ height:6px; background:#2a2a5a; border-radius:3px; overflow:hidden; }}
.bar-fill {{ height:100%; border-radius:3px; }}
.suggestions {{ display:flex; flex-direction:column; gap:10px; margin:12px 0; }}
.suggestion {{ padding:14px 16px; border-radius:8px; border-left:4px solid; position:relative; }}
.suggestion.high {{ background:#2a0f0f; border-color:#f44336; }}
.suggestion.medium {{ background:#1a1a3a; border-color:#ff9800; }}
.suggestion.low {{ background:#0f0f23; border-color:#555; }}
.suggestion .sug-category {{ display:inline-block; font-size:11px; padding:1px 8px; border-radius:3px; margin-bottom:6px; }}
.suggestion .sug-target {{ font-weight:600; font-size:14px; }}
.suggestion .sug-text {{ font-size:13px; color:#ccc; margin-top:6px; line-height:1.6; }}
.suggestion .sug-evidence {{ font-size:11px; color:#666; margin-top:6px; border-top:1px solid #2a2a5a; padding-top:6px; }}
.suggestion .sug-source {{ font-size:10px; color:#444; float:right; }}
.cat-机制 {{ background:#4a148c; color:#ce93d8; }}
.cat-数值 {{ background:#1a237e; color:#90caf9; }}
.cat-价格 {{ background:#e65100; color:#ffcc80; }}
.cat-奖励 {{ background:#004d40; color:#80cbc4; }}
.cat-阈值 {{ background:#3e2723; color:#a1887f; }}
.detail-group {{ margin:8px 0; background:#16163a; border-radius:10px; border:1px solid #2a2a5a; overflow:hidden; }}
.detail-header {{ padding:12px 16px; cursor:pointer; display:flex; align-items:center; gap:10px; font-size:14px; font-weight:600; user-select:none; }}
.detail-header:hover {{ background:#1e1e4a; }}
.detail-header .arrow {{ transition:transform 0.2s; }}
.detail-header.open .arrow {{ transform:rotate(90deg); }}
.detail-body {{ padding:0 16px 16px; display:none; }}
.detail-body.open {{ display:block; }}
.type-row {{ display:flex; align-items:center; gap:10px; padding:6px 0; font-size:13px; border-bottom:1px solid #1e1e3a; }}
.type-row:last-child {{ border-bottom:none; }}
.type-row .name {{ width:140px; }}
.type-row .stat {{ width:70px; text-align:center; }}
.type-row .bar {{ flex:1; max-width:200px; }}
.at-grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:10px; margin:12px 0; }}
.at-card {{ background:#16163a; border-radius:8px; padding:12px; border:1px solid #2a2a5a; }}
.at-card .at-name {{ font-size:14px; font-weight:600; }}
.at-card .at-row {{ display:flex; justify-content:space-between; font-size:12px; margin:4px 0; color:#aaa; }}
.at-diff-pos {{ color:#4caf50; }}
.at-diff-neg {{ color:#f44336; }}
.inflate-card {{ background:#16163a; border-radius:8px; padding:10px 14px; border:1px solid #2a2a5a; font-size:13px; }}
.footer {{ text-align:center; font-size:12px; color:#555; margin:40px 0 20px; }}
</style>
</head>
<body>
<div class="container">

<h1>🧠 NinKing MBTI 32型 · 模拟测试报告</h1>
<div class="report-meta">
  <span class="meta-tag">📅 {timestamp}</span>
  <span class="meta-tag">🎯 {len(results)} 型</span>
  <span class="meta-tag">🔄 {results[0]['runs'] if results else 0} 次/型</span>
  <span class="meta-tag">📂 data_personality/</span>
</div>

<h2>📊 总览</h2>
<div class="kpi-grid" id="kpiGrid"></div>

<h2>⚠️ 关键发现</h2>
<div class="findings" id="findingsContainer"></div>

<h2>📈 数值膨胀 / 超模分析</h2>
<div id="inflationContainer"></div>

<h2>🔧 游戏机制调整建议</h2>
<p style="font-size:12px;color:#888;margin-bottom:8px;">
  建议基于多维数据分析自动生成，聚焦具体游戏机制调整方向。
</p>
<div class="suggestions" id="suggestionsContainer"></div>

<h2>⚖️ A/T 自信 vs 动荡 对比</h2>
<div id="atContainer"></div>

<h2>📋 各组明细</h2>
<div id="detailContainer"></div>

<div class="footer">
  NinKing MBTI 模拟测试 · 由 analyze_mbti_report.py + render_mbti_html.py 自动生成 · {timestamp}
</div>

</div>

<script>
const RESULTS = {results_json};
const FINDINGS = {findings_json};
const INFLATION = {inflation_json};
const SUGGESTIONS = {suggestions_json};
const AT_PAIRS = {at_json};

(function() {{
  const grid = document.getElementById('kpiGrid');
  const b8Rates = RESULTS.map(r => r.b8_pass_rate);
  const avgB8 = (b8Rates.reduce((s,v) => s+v, 0) / b8Rates.length).toFixed(1);
  const b8Any = b8Rates.filter(v => v > 0).length;
  const b8Zero = b8Rates.filter(v => v === 0).length;
  const avgTrig = (RESULTS.reduce((s,r) => s + r.avg_trigger, 0) / RESULTS.length).toFixed(1);
  const b8Best = Math.max(...b8Rates);
  const b8Worst = Math.min(...b8Rates);
  grid.innerHTML = `
    <div class="kpi-card"><div class="kpi-label">平均 B8 通关率</div><div class="kpi-value" style="color:#ffd700;">${{avgB8}}%</div><div class="kpi-sub">${{b8Any}}型通关 / ${{b8Zero}}型未通</div></div>
    <div class="kpi-card"><div class="kpi-label">最佳 / 最差</div><div class="kpi-value" style="font-size:22px;"><span style="color:#4caf50;">${{b8Best}}%</span> / <span style="color:#f44336;">${{b8Worst}}%</span></div><div class="kpi-sub">跨度 ${{(b8Best - b8Worst).toFixed(1)}}%</div></div>
    <div class="kpi-card"><div class="kpi-label">平均触发率</div><div class="kpi-value" style="color:#42a5f5;">${{avgTrig}}%</div><div class="kpi-sub">忍者激活水平</div></div>
    <div class="kpi-card"><div class="kpi-label">测试规模</div><div class="kpi-value" style="color:#ab47bc;">${{RESULTS.length}}型</div><div class="kpi-sub">× ${{RESULTS[0]?.runs || 0}} 次运行</div></div>
  `;
}})();

(function() {{
  const container = document.getElementById('findingsContainer');
  let html = '';
  for (const f of FINDINGS) {{
    const cls = f.severity === 'critical' ? 'critical' : f.severity === 'weak' ? 'weak' : f.severity === 'op' ? 'op' : f.severity === 'warning' ? 'warning' : 'normal';
    if (f.type === 'individual') {{
      html += `<div class="finding ${{cls}}"><span class="rating">${{f.rating}}</span><span>${{f.msg}}</span></div>`;
    }} else {{
      html += `<div class="finding ${{cls}}"><span class="rating">${{f.rating}}</span><span><b>${{f.icon}} ${{f.group}}</b> B8均 <b>${{f.avg_b8}}%</b> (${{f.b8_wins}}/${{f.total}}型通关) · 最佳 ${{f.best_name}} ${{f.best_rate}}% · 最弱 ${{f.worst_name}} ${{f.worst_rate}}%</span></div>`;
    }}
  }}
  container.innerHTML = html;
}})();

(function() {{
  const container = document.getElementById('inflationContainer');
  if (!INFLATION) {{ container.innerHTML = '<p style="color:#888;">无B8通关数据，无法分析膨胀</p>'; return; }}
  const fmt = n => {{
    if (n >= 1e9) return (n/1e9).toFixed(2)+'B';
    if (n >= 1e6) return (n/1e6).toFixed(1)+'M';
    if (n >= 1e3) return (n/1e3).toFixed(0)+'K';
    return n.toString();
  }};
  let html = '<div class="inflate-card" style="margin-bottom:12px;">';
  html += `<div>目标分数: <b>${{fmt(INFLATION.target)}}</b></div>`;
  html += `<div>B8_P50范围: <b>${{fmt(INFLATION.min_score)}}</b> ~ <b>${{fmt(INFLATION.max_score)}}</b> (差距 <b style="color:${{INFLATION.gap_ratio > 100 ? '#f44336' : '#ff9800'}};">${{INFLATION.gap_ratio}}x</b>)</div>`;
  html += `<div>平均得分: <b>${{fmt(INFLATION.avg_score)}}</b> = 目标的 <b>${{(INFLATION.avg_score / INFLATION.target).toFixed(1)}}x</b></div>`;
  html += '</div><table><tr><th>类型</th><th>P50得分</th><th>膨胀系数</th><th>等级</th></tr>';
  for (const d of INFLATION.details.slice(0, 10)) {{
    const color = d.level === '严重膨胀' ? '#f44336' : d.level === '明显膨胀' ? '#ff9800' : d.level === '关注' ? '#ffd700' : '#4caf50';
    html += `<tr><td>${{d.icon}} ${{d.name}}</td><td>${{fmt(d.b8_p50)}}</td><td>${{d.ratio}}x</td><td style="color:${{color}};">${{d.level}}</td></tr>`;
  }}
  if (INFLATION.details.length > 10) html += `<tr><td colspan="4" style="color:#666;">...共 ${{INFLATION.details.length}} 型</td></tr>`;
  html += '</table>';
  container.innerHTML = html;
}})();

(function() {{
  const container = document.getElementById('suggestionsContainer');
  let html = '';
  for (const s of SUGGESTIONS) {{
    const cat = s.category || '机制';
    const catClass = 'cat-'+cat;
    const emoji = cat==='机制'?'🔧':cat==='数值'?'⚖️':cat==='价格'?'💰':cat==='奖励'?'🎁':'🎯';
    html += `<div class="suggestion ${{s.priority}}">`;
    html += `<div class="sug-category ${{catClass}}">${{emoji}} ${{cat}}</div>`;
    html += `<div class="sug-target">${{s.target}}</div>`;
    html += `<div class="sug-text">💡 ${{s.suggestion}}</div>`;
    if (s.evidence) html += `<div class="sug-evidence">📊 ${{s.evidence}}</div>`;
    html += `<div class="sug-source">来源: ${{s.source || 'auto'}}</div></div>`;
  }}
  container.innerHTML = html;
}})();

(function() {{
  const container = document.getElementById('atContainer');
  if (!AT_PAIRS || !AT_PAIRS.length) {{ container.innerHTML = '<p style="color:#888;">无A/T配对数据</p>'; return; }}
  let html = '<div class="at-grid">';
  for (const p of AT_PAIRS) {{
    const diffClass = p.diff > 0 ? 'at-diff-pos' : p.diff < 0 ? 'at-diff-neg' : '';
    html += `<div class="at-card"><div class="at-name">${{p.icon}} ${{p.name}}</div>`;
    html += `<div class="at-row"><span>-A: ${{p.a_b8}}% (触发 ${{p.a_trig}}%)</span><span>-T: ${{p.t_b8}}% (触发 ${{p.t_trig}}%)</span></div>`;
    html += `<div class="at-row"><span>B8差距: <span class="${{diffClass}}">${{p.diff > 0 ? '+':''}}${{p.diff}}%</span></span></div></div>`;
  }}
  html += '</div>';
  container.innerHTML = html;
}})();

(function() {{
  const GROUP_ORDER = ['稳妥型','理财型','赌狗型','灵活型','收集型','感性型','混沌型'];
  const GROUP_ICONS = {{'稳妥型':'🛡️','理财型':'💰','赌狗型':'🎲','灵活型':'🦎','收集型':'📋','感性型':'🎭','混沌型':'🧪'}};
  const container = document.getElementById('detailContainer');
  let html = '';
  for (const g of GROUP_ORDER) {{
    const members = RESULTS.filter(r => r.group === g);
    if (!members.length) continue;
    const icon = GROUP_ICONS[g] || '❓';
    const avgB8 = (members.reduce((s,r) => s+r.b8_pass_rate, 0)/members.length).toFixed(1);
    html += `<div class="detail-group"><div class="detail-header" onclick="this.classList.toggle('open');this.nextElementSibling.classList.toggle('open')">`;
    html += `<span class="arrow">▶</span> ${{icon}} ${{g}} <span style="color:#888;font-weight:400;font-size:12px;">(${{members.length}}型 · B8均 ${{avgB8}}%)</span>`;
    html += `</div><div class="detail-body">`;
    for (const r of members) {{
      const b8c = r.b8_pass_rate >= 30 ? '#4caf50' : r.b8_pass_rate >= 10 ? '#ff9800' : '#f44336';
      html += `<div class="type-row"><span class="name">${{r.icon}} ${{r.name}}</span>`;
      html += `<span class="stat" style="color:${{b8c}};">${{r.b8_pass_rate}}%</span>`;
      html += `<span class="stat">B${{r.max_barrier}}</span>`;
      html += `<span class="stat">${{r.avg_trigger}}%</span>`;
      html += `<span class="stat">${{r.avg_active}}</span>`;
      html += `<span class="bar"><div class="bar-bg"><div class="bar-fill" style="width:${{Math.min(r.b8_pass_rate,100)}}%;background:${{b8c}}"></div></div></span>`;
      html += `</div>`;
    }}
    html += `</div></div>`;
  }}
  container.innerHTML = html;
}})();
</script>
</body>
</html>"""
    return html


def main():
    import argparse
    parser = argparse.ArgumentParser(description="NinKing MBTI 报告 HTML 渲染器")
    parser.add_argument("--input", type=str, default=None,
                        help="JSON 报告数据路径（默认: reports/ 下最新文件）")
    parser.add_argument("--output", type=str, default=None,
                        help="HTML 输出路径（默认: reports/mbti_report_*.html）")
    args = parser.parse_args()

    # 找输入
    json_path = args.input
    if json_path is None:
        json_path = find_latest_json()
    if json_path is None or not os.path.isfile(json_path):
        print(f"❌ 输入 JSON 文件不存在: {json_path}")
        sys.exit(1)

    print(f"📄 读取报告数据: {json_path}")
    report_data = load_report_data(json_path)
    timestamp = report_data.get("meta", {}).get("timestamp_file", "unknown")
    print(f"   时间戳: {report_data.get('meta', {}).get('timestamp', '?')}")
    print(f"   类型数: {report_data.get('meta', {}).get('num_types', 0)}")

    # 渲染 HTML
    html = render_html(report_data)

    # 输出
    if args.output is None:
        os.makedirs(REPORTS_DIR, exist_ok=True)
        args.output = os.path.join(REPORTS_DIR, f"mbti_report_{timestamp}.html")

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"✅ HTML 报告已生成: {args.output}")
    print(f"   大小: {os.path.getsize(args.output):,} bytes")


if __name__ == "__main__":
    main()
