#!/usr/bin/env python3
"""
NinKing 关卡模拟 — 结果分析 & HTML 可视化
"""
import json
import os
import csv

# ══════════════════════════════════════════
# 加载数据
# ══════════════════════════════════════════

def load_all_data(data_dir):
    """加载所有 JSON 结果文件"""
    scenarios = []
    for fname in os.listdir(data_dir):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(data_dir, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            data = json.load(f)
        scenarios.append(data)
    return scenarios


# ══════════════════════════════════════════
# CSV 输出 — 阈值对比表
# ══════════════════════════════════════════

def export_threshold_csv(scenarios, output_path):
    """输出阈值对比表 CSV"""
    # 收集封印列表
    seal_list = []
    for sc in scenarios:
        for st in sc["seal_stats"]:
            key = (st["barrier"], st["seal"], st["seal_type"])
            if key not in seal_list:
                seal_list.append(key)
    seal_list.sort()

    # CSV header
    headers = ["结界", "封印", "目标阈值"]
    for sc in scenarios:
        tag = f"{sc['strategy']}_{sc['budget']}"
        headers += [f"{tag}_P50", f"{tag}_P75", f"{tag}_通过率"]

    with open(output_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(headers)

        for barrier, seal, seal_type in seal_list:
            row = [f"结界{barrier}", seal_type]
            target = 0
            extra = []

            for sc in scenarios:
                for st in sc["seal_stats"]:
                    if st["barrier"] == barrier and st["seal"] == seal:
                        if target == 0:
                            target = st["target"]
                        p50 = st["p50"]
                        p75 = st["p75"]
                        pr = f"{st['pass_rate']:.0%}"
                        extra += [f"{p50:,}", f"{p75:,}", pr]
                        break
                else:
                    extra += ["—", "—", "—"]

            row = [f"结界{barrier}", seal_type, f"{target:,}"] + extra
            writer.writerow(row)

    print(f"阈值对比表 → {output_path}")


# ══════════════════════════════════════════
# HTML 可视化
# ══════════════════════════════════════════

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NinKing 关卡难度模拟 — {strategy} / {budget}</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<style>
  body {{ font-family: -apple-system, "Microsoft YaHei", sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background: #1a1a2e; color: #e0e0e0; }}
  h1 {{ color: #ffd700; border-bottom: 2px solid #ffd70044; padding-bottom: 8px; }}
  h2 {{ color: #a0d2ff; margin-top: 30px; }}
  .meta {{ color: #aaa; font-size: 14px; margin-bottom: 20px; }}
  .chart-container {{ background: #16213e; border-radius: 12px; padding: 20px; margin: 20px 0; }}
  table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
  th, td {{ padding: 8px 12px; text-align: right; border-bottom: 1px solid #333; }}
  th {{ background: #0f3460; color: #ffd700; }}
  tr:hover {{ background: #1a3a5c; }}
  .pass {{ color: #4caf50; }}
  .fail {{ color: #f44336; }}
  .warn {{ color: #ff9800; }}
  .summary {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; margin: 20px 0; }}
  .card {{ background: #16213e; border-radius: 8px; padding: 16px; text-align: center; }}
  .card .num {{ font-size: 28px; font-weight: bold; color: #ffd700; }}
  .card .label {{ font-size: 12px; color: #aaa; margin-top: 4px; }}
  .note {{ font-size: 13px; color: #888; font-style: italic; margin-top: 20px; }}
</style>
</head>
<body>
<h1>{strategy} — {budget_label}</h1>
<div class="meta">
  预算比例: {budget_ratio} | 每场景 {runs} 次模拟 | 共 8 结界 × 3 封印
</div>

<div class="summary">
  <div class="card">
    <div class="num">结界{avg_max_barrier}</div>
    <div class="label">平均到达结界</div>
  </div>
  <div class="card">
    <div class="num">{b8_pass_count}/{runs}</div>
    <div class="label">结界8通关次数</div>
  </div>
  <div class="card">
    <div class="num">{b8_pass_rate:.0%}</div>
    <div class="label">结界8通过率</div>
  </div>
  <div class="card">
    <div class="num">{avg_ninja_eff:.1%}</div>
    <div class="label">忍者平均触发率</div>
  </div>
</div>

<div class="chart-container">
  <canvas id="scoreChart"></canvas>
</div>

<table>
  <tr>
    <th>结界</th>
    <th>目标</th>
    <th>P10</th>
    <th>P25</th>
    <th>P50</th>
    <th>P75</th>
    <th>P90</th>
    <th>通过率</th>
    <th>忍者触发</th>
  </tr>
  {table_rows}
</table>

<div class="note">
  * 对数刻度, P10-P90 色带显示分数分布范围<br>
  * P50 < 目标 = 该关对半开策略来说偏难<br>
  * 忍者触发率低说明买的忍者很少在实际发牌中生效<br>
  * 星图/Boss/牌面增强均未模拟, 实际玩家分数会更高
</div>

<script>
const labels = {chart_labels};
const targets = {chart_targets};
const p10 = {chart_p10};
const p25 = {chart_p25};
const p50 = {chart_p50};
const p75 = {chart_p75};
const p90 = {chart_p90};

new Chart(document.getElementById('scoreChart'), {{
  type: 'line',
  data: {{
    labels: labels,
    datasets: [
      {{
        label: '当前阈值',
        data: targets,
        borderColor: '#ff4444',
        borderWidth: 2,
        borderDash: [6, 3],
        pointRadius: 0,
        fill: false,
      }},
      {{
        label: 'P75',
        data: p75,
        borderColor: '#ffd700',
        borderWidth: 2,
        pointRadius: 0,
        fill: '-1',
        backgroundColor: 'rgba(255, 215, 0, 0.08)',
      }},
      {{
        label: 'P50 (中位数)',
        data: p50,
        borderColor: '#4caf50',
        borderWidth: 2,
        pointRadius: 0,
        fill: '-1',
        backgroundColor: 'rgba(76, 175, 80, 0.08)',
      }},
      {{
        label: 'P25',
        data: p25,
        borderColor: '#2196f3',
        borderWidth: 1,
        borderDash: [3, 3],
        pointRadius: 0,
        fill: false,
      }},
      {{
        label: 'P10',
        data: p10,
        borderColor: '#9c27b0',
        borderWidth: 1,
        borderDash: [3, 3],
        pointRadius: 0,
        fill: false,
      }},
    ]
  }},
  options: {{
    responsive: true,
    maintainAspectRatio: false,
    plugins: {{
      title: {{ display: true, text: '每关分数分布 vs 当前阈值', color: '#e0e0e0' }},
      legend: {{ labels: {{ color: '#e0e0e0' }} }},
    }},
    scales: {{
      x: {{ ticks: {{ color: '#aaa' }} }},
      y: {{
        type: 'logarithmic',
        title: {{ display: true, text: '分数 (对数刻度)', color: '#aaa' }},
        ticks: {{ color: '#aaa', callback: v => v >= 1000 ? (v/1000).toFixed(0) + 'k' : v }},
        min: 10,
      }}
    }}
  }}
}});
</script>
</body>
</html>"""


def generate_html(scenario, output_path):
    """从场景数据生成 HTML"""
    strategy = scenario["strategy"]
    budget = scenario["budget"]
    budget_ratio = scenario["budget_ratio"]
    runs = scenario["runs"]
    stats = scenario["seal_stats"]

    budget_label = f"极限预算({budget_ratio:.0%})" if budget == "extreme" else f"保守预算({budget_ratio:.0%})"

    # 摘要
    b8_count = sum(1 for s in stats if s["barrier"] == 8 and s["seal"] == 2 and s["pass_count"] > 0)
    b8_pass_rate = b8_count / runs if runs > 0 else 0
    avg_ninja_eff = sum(s["avg_trigger_rate"] for s in stats) / len(stats) if stats else 0

    # 平均到达结界: 看最大能打到哪
    max_barriers = []
    for s in stats:
        if s["pass_count"] > 0:
            max_barriers.append(s["barrier"])
    avg_max = max(max_barriers) if max_barriers else 0

    # 图表数据
    chart_labels = []
    chart_targets = []
    chart_p10 = []
    chart_p25 = []
    chart_p50 = []
    chart_p75 = []
    chart_p90 = []

    table_rows = ""

    for st in stats:
        label = f"结界{st['barrier']}-{st['seal_type']}"
        chart_labels.append(f"B{st['barrier']}{st['seal_type'][0]}")
        chart_targets.append(st["target"])
        chart_p10.append(st["p10"])
        chart_p25.append(st["p25"])
        chart_p50.append(st["p50"])
        chart_p75.append(st["p75"])
        chart_p90.append(st["p90"])

        # 通过率颜色
        pr = st["pass_rate"]
        if pr >= 0.8:
            pr_class = "pass"
        elif pr >= 0.5:
            pr_class = "warn"
        else:
            pr_class = "fail"

        table_rows += (
            f"<tr>"
            f"<td style='text-align:left'>结界{st['barrier']}-{st['seal_type']}</td>"
            f"<td>{st['target']:,}</td>"
            f"<td>{st['p10']:,}</td>"
            f"<td>{st['p25']:,}</td>"
            f"<td>{st['p50']:,}</td>"
            f"<td>{st['p75']:,}</td>"
            f"<td>{st['p90']:,}</td>"
            f"<td class='{pr_class}'>{pr:.0%}</td>"
            f"<td>{st['avg_trigger_rate']:.0%}</td>"
            f"</tr>\n"
        )

    html = HTML_TEMPLATE.format(
        strategy=strategy,
        budget=budget,
        budget_label=budget_label,
        budget_ratio=budget_ratio,
        runs=runs,
        avg_max_barrier=avg_max,
        b8_pass_count=b8_count,
        b8_pass_rate=b8_pass_rate,
        avg_ninja_eff=avg_ninja_eff,
        chart_labels=json.dumps(chart_labels, ensure_ascii=False),
        chart_targets=json.dumps(chart_targets),
        chart_p10=json.dumps(chart_p10),
        chart_p25=json.dumps(chart_p25),
        chart_p50=json.dumps(chart_p50),
        chart_p75=json.dumps(chart_p75),
        chart_p90=json.dumps(chart_p90),
        table_rows=table_rows,
    )

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"可视化 → {output_path}")


# ══════════════════════════════════════════
# 主入口
# ══════════════════════════════════════════

def main(data_dir=None, output_dir=None):
    if data_dir is None:
        data_dir = os.path.join(os.path.dirname(__file__), "..", "..",
                                "docs", "ninking", "08-testing", "data")
    if output_dir is None:
        output_dir = data_dir

    data_dir = os.path.normpath(data_dir)
    output_dir = os.path.normpath(output_dir)

    scenarios = load_all_data(data_dir)
    print(f"加载 {len(scenarios)} 个场景数据\n")

    # 阈值对比表
    csv_path = os.path.join(output_dir, "threshold_comparison.csv")
    export_threshold_csv(scenarios, csv_path)

    # 每个场景一个 HTML
    for sc in scenarios:
        html_name = f"{sc['strategy']}_{sc['budget']}.html"
        html_path = os.path.join(output_dir, html_name)
        generate_html(sc, html_path)

    print(f"\n完成! 输出目录: {output_dir}")


if __name__ == "__main__":
    main()
