"""Generate README charts (PNG) from the gold tables.

Usage:
    pip install -r requirements-extra.txt
    export GCP_PROJECT=your-project-id
    export GOLD_DATASET=ga4_portfolio_gold      # optional, this is the default
    python scripts/make_charts.py
"""
import os
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from google.cloud import bigquery  # noqa: E402
import pandas as pd  # noqa: E402

PROJECT = os.environ["GCP_PROJECT"]
DATASET = os.environ.get("GOLD_DATASET", "ga4_portfolio_gold")
OUT_DIR = Path("docs/img")


def query(client: bigquery.Client, sql: str):
    return client.query(sql, location="US").to_dataframe()


def funnel_chart(client: bigquery.Client) -> None:
    df = query(
        client,
        f"""
        select step_order, step, sessions, pct_of_previous_step, pct_of_first_step
        from `{PROJECT}.{DATASET}.fct_funnel_overall`
        order by step_order
        """,
    )
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.barh(df["step"][::-1], df["sessions"][::-1], color="#4c78a8")
    for y, (sessions, pct) in enumerate(
        zip(df["sessions"][::-1], df["pct_of_previous_step"][::-1])
    ):
        label = f"{int(sessions):,}" + ("" if pct != pct else f"  ({pct:.1%} of previous)")
        ax.text(sessions, y, " " + label, va="center", fontsize=9)
    ax.set_title("Closed purchase funnel (sessions)")
    ax.set_xlabel("Sessions")
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_xlim(0, df["sessions"].max() * 1.35)
    fig.tight_layout()
    fig.savefig(OUT_DIR / "funnel.png", dpi=150)
    plt.close(fig)


def step_duration_chart(client: bigquery.Client) -> None:
    df = query(
        client,
        f"""
        select step, median_seconds, p25_seconds, p75_seconds
        from `{PROJECT}.{DATASET}.fct_step_duration`
        where device_category = 'all'
        """,
    )
    order = [
        "view_to_cart_s",
        "cart_to_checkout_s",
        "checkout_to_shipping_s",
        "shipping_to_payment_s",
        "payment_to_purchase_s",
    ]
    df = df[df["step"].isin(order)].copy()
    df["step"] = pd.Categorical(df["step"], categories=order, ordered=True)
    df = df.sort_values("step")
    df["step"] = df["step"].astype(str)
    for col in ["median_seconds", "p25_seconds", "p75_seconds"]:
        df[col] = pd.to_numeric(df[col], errors="coerce").astype(float)
    df = df.dropna(subset=["median_seconds"])
    missing = [step for step in order if step not in set(df["step"])]
    if missing:
        print(f"WARNING: no data for steps: {missing}")
    if df.empty:
        raise SystemExit("fct_step_duration returned no 'all' rows; chart not saved.")
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(df["step"], df["median_seconds"], color="#f58518")
    ax.errorbar(
        df["step"],
        df["median_seconds"],
        yerr=[
            df["median_seconds"] - df["p25_seconds"],
            df["p75_seconds"] - df["median_seconds"],
        ],
        fmt="none",
        ecolor="black",
        capsize=4,
    )
    ax.set_title("Median time between funnel steps (bars: p25-p75)")
    ax.set_ylabel("Seconds")
    ax.tick_params(axis="x", rotation=20)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT_DIR / "step_duration.png", dpi=150)
    plt.close(fig)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    client = bigquery.Client(project=PROJECT)
    funnel_chart(client)
    step_duration_chart(client)
    print(f"Charts saved in {OUT_DIR}/")


if __name__ == "__main__":
    main()
