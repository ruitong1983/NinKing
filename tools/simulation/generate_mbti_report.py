#!/usr/bin/env python3
"""
NinKing MBTI 报告生成器 — 兼容入口（委派给 analyze_mbti_report.py + render_mbti_html.py）

保留此文件以兼容旧调用方式（如 sim_runner_personality.py 的 --report 标志）。

用法（兼容）:
    python generate_mbti_report.py                              # 分析+渲染一步完成
    python generate_mbti_report.py --input 某路径                # 指定数据目录
    python generate_mbti_report.py --output 某路径/myreport.html # 指定输出

新用法（推荐）:
    python analyze_mbti_report.py --input DIR --render           # 分析 JSON → 自动渲染 HTML
    python render_mbti_html.py --input reports/data.json         # 单独渲染 HTML
"""
import os
import sys
import json
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPORTS_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..",
                 "docs", "ninking", "08-testing", "reports")
)

# ── 委派函数（给 sim_runner_personality.py 调用）──

def generate_report(data_dir=None, output_path=None):
    """
    兼容入口：运行分析 → 生成 JSON → 渲染 HTML 一站式。

    Args:
        data_dir: 数据目录（默认 data_personality）
        output_path: HTML 输出路径（可选）

    Returns:
        HTML 文件路径，或 None
    """
    # Step 1: 分析 → JSON
    from analyze_mbti_report import generate_report_data, save_report_json

    report_data = generate_report_data(data_dir)
    if report_data is None:
        return None

    json_path = save_report_json(report_data)

    # Step 2: JSON → HTML
    from render_mbti_html import render_html

    html = render_html(report_data)

    if output_path is None:
        os.makedirs(REPORTS_DIR, exist_ok=True)
        ts = report_data["meta"]["timestamp_file"]
        output_path = os.path.join(REPORTS_DIR, f"mbti_report_{ts}.html")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"✅ HTML 报告已生成: {output_path}")
    print(f"   大小: {os.path.getsize(output_path):,} bytes")
    return output_path


# ── CLI: 兼容模式，直接委派 analyze_mbti_report.py ──

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="NinKing MBTI 报告生成器（兼容入口）")
    parser.add_argument("--input", type=str, default=None,
                        help="数据目录（默认 data_personality）")
    parser.add_argument("--output", type=str, default=None,
                        help="输出 HTML 路径（可选）")
    args = parser.parse_args()

    # 委派给 analyze_mbti_report.py
    analyze_script = os.path.join(SCRIPT_DIR, "analyze_mbti_report.py")
    cmd = [sys.executable, analyze_script, "--render"]
    if args.input:
        cmd += ["--input", args.input]
    print(f"📎 委派: {' '.join(cmd)}")
    sys.exit(subprocess.call(cmd))
