+++
title = '用命中率驱动 KV 上报，别用状态机'
date = 2026-06-16
draft = false
description = '在 LLM 推理网关里上报 KV cache 位置时，用 trie 的 hit_ratio 决定全量/增量，比 worker_synced 状态机更可靠。'
tags = ['llm', 'gateway', 'distributed-systems']
categories = ['推理系统']
toc = true
+++

## 背景

在多 worker 的 LLM 推理网关里，每个请求的 KV cache 落在某个 worker 的某段显存上。
gateway 需要维护一张「请求 → KV 位置」的路由表，好让 prefix 复用、迁移、驱逐都能精准命中。

这张表的更新有个朴素设计：每个 worker 维护一个 `worker_synced` 状态——
当它和 gateway 的视图「对齐」时走增量上报，否则走全量。看起来很合理。

<!--more-->

## 坑：状态机会撒谎

实际跑起来发现，`worker_synced` 这个布尔状态会**撒谎**：

- worker 重启、显存回收、并发驱逐之后，「对齐」这个判断本身就已经不对齐了。
- 一旦状态机误判为「已对齐」，后续只上报增量，gateway 的视图就和真实情况**静默漂移**。
- 表现就是偶发的 prefix 复用失败、命中率掉点，而且很难定位，因为「上报表上一切正常」。

这就是 commit `de1e993` 里踩的坑。

## 用命中率驱动，而不是状态驱动

关键转变：**不要用一个离散的布尔状态来描述「对齐」，而是用一个连续的、可观测的指标来驱动决策。**

我们手上本来就有这个指标——trie 的 `hit_ratio`：每次查 trie，命中了多少 prefix。
当 `hit_ratio` 跌破阈值，说明 gateway 的视图已经和真实分布脱节，这时强制走一次全量上报重建；
其余时间走增量。

```go
func (g *Gateway) reportPolicy() Policy {
    ratio := g.trie.HitRatio(g.window)
    switch {
    case ratio < g.cfg.fullResyncThreshold: // 视图可能漂移，强制全量
        return FullReport
    default:
        return IncrementalReport
    }
}
```

为什么这更可靠：

1. **指标是被观测出来的，不是被声明出来的。** `hit_ratio` 直接反映「视图对不对齐」的后果，而 `worker_synced` 只是自我宣告。
2. **自带负反馈。** 漂移越严重，命中率越低，越容易触发全量重建；对齐时命中率高，自然走增量。系统会自己收敛。
3. **可观测。** 命中率本来就是要监控的指标，复用它驱动一致性，等于把正确性和监控对齐了。

> 「状态」描述的是*你认为自己处于哪里*；「指标」描述的是*你实际表现如何*。
> 分布式系统里两者冲突时，永远相信指标。

## 小结

如果一个状态变量必须保持正确，系统才能正确，那它就是个隐患。
能换成「从可观测结果反推」的设计，就换掉——哪怕多花一点观测成本，也远比静默漂移便宜。
