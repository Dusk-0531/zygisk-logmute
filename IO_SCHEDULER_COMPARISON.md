# Linux I/O 调度器对比表 (I/O Scheduler Comparison)

## 概述 (Overview)

本文档详细对比了 Linux 内核中常用的 I/O 调度器：Kyber、Noop、MQ-Deadline 和 Deadline。这些调度器决定了块设备请求的处理顺序，对系统性能有重要影响。

This document provides a detailed comparison of commonly used I/O schedulers in the Linux kernel: Kyber, Noop, MQ-Deadline, and Deadline. These schedulers determine the order in which block device requests are processed, significantly impacting system performance.

---

## 基本信息对比表 (Basic Information Comparison)

| 特性 (Feature) | Kyber | Noop | MQ-Deadline | Deadline |
|:---|:---|:---|:---|:---|
| **中文名称** | Kyber 调度器 | 无操作调度器 | 多队列截止时间调度器 | 截止时间调度器 |
| **引入内核版本** | Linux 4.12+ | Linux 2.6+ | Linux 4.11+ (blk-mq) | Linux 2.6+ |
| **架构支持** | Multi-Queue (blk-mq) | 单队列/多队列 | Multi-Queue (blk-mq) | 单队列 (legacy) |
| **复杂度** | 中等 | 极简 | 中等 | 中等 |
| **主要设计目标** | 延迟控制 | 零开销 | 平衡吞吐量和延迟 | 防止饿死 |
| **默认使用场景** | SSD/NVMe (现代设备) | 虚拟化、RAM盘 | SSD/NVMe (通用) | 传统 HDD/SSD |

---

## 详细特性对比 (Detailed Feature Comparison)

### 1. Kyber 调度器

**核心特点 (Core Features):**
- 专为现代高速 SSD 和 NVMe 设备设计
- 使用令牌桶算法控制请求流量
- 动态调整队列深度以控制延迟
- 区分同步和异步 I/O 请求
- 实时监控设备延迟并自动调整

**工作原理 (How It Works):**
```
请求分类 → 令牌桶限流 → 队列深度调整 → 延迟目标控制
```

**优势 (Advantages):**
- ✅ 优秀的延迟控制能力
- ✅ 防止 I/O 拥塞
- ✅ 适合交互式工作负载
- ✅ 自适应调整性能
- ✅ 对 SSD/NVMe 优化良好

**劣势 (Disadvantages):**
- ❌ 吞吐量可能不如其他调度器
- ❌ 需要额外的 CPU 开销
- ❌ 不适合纯顺序 I/O 场景
- ❌ 配置参数较为复杂

**适用场景 (Use Cases):**
- 桌面系统、笔记本
- 需要低延迟响应的应用
- 数据库服务器 (OLTP)
- 虚拟化主机
- 移动设备和智能手机

**可调参数 (Tunable Parameters):**
- `read_lat_nsec`: 读延迟目标 (默认: 2000000 ns)
- `write_lat_nsec`: 写延迟目标 (默认: 10000000 ns)

---

### 2. Noop 调度器

**核心特点 (Core Features):**
- 最简单的 I/O 调度器
- 几乎不进行任何调度操作
- 按照 FIFO (先进先出) 顺序处理请求
- 只进行基本的请求合并
- 极低的 CPU 开销

**工作原理 (How It Works):**
```
I/O 请求 → 简单合并相邻请求 → FIFO 队列 → 直接提交
```

**优势 (Advantages):**
- ✅ CPU 开销最小
- ✅ 实现极其简单
- ✅ 适合随机访问设备
- ✅ 无调度延迟
- ✅ 适合虚拟化环境

**劣势 (Disadvantages):**
- ❌ 没有 I/O 优先级控制
- ❌ 可能导致请求饿死
- ❌ 不适合机械硬盘
- ❌ 无法优化寻道时间
- ❌ 缺乏公平性保证

**适用场景 (Use Cases):**
- 虚拟机 (Guest OS)
- RAM 磁盘和内存设备
- SSD 设备 (仅在虚拟化或特殊场景)
- 闪存存储 (嵌入式系统)
- 简单嵌入式系统

**可调参数 (Tunable Parameters):**
- 几乎无可调参数 (极简设计)

---

### 3. MQ-Deadline 调度器

**核心特点 (Core Features):**
- Deadline 调度器的多队列版本
- 为每个 CPU 核心维护独立队列
- 按照截止时间排序请求
- 区分读写请求，读请求优先
- 防止请求饿死

**工作原理 (How It Works):**
```
请求分类 (读/写) → 截止时间排序 → 批处理合并 → 多队列分发
```

**优势 (Advantages):**
- ✅ 平衡吞吐量和延迟
- ✅ 防止请求饿死
- ✅ 适合多核 CPU
- ✅ 读操作优先处理
- ✅ 良好的通用性能

**劣势 (Disadvantages):**
- ❌ 不如 Kyber 的延迟控制精细
- ❌ 在某些工作负载下性能不佳
- ❌ 配置复杂度中等
- ❌ 对随机写入优化有限

**适用场景 (Use Cases):**
- 服务器工作负载
- 通用 SSD/NVMe 设备
- 混合读写场景
- 文件服务器
- Web 服务器

**可调参数 (Tunable Parameters):**
- `read_expire`: 读请求过期时间 (默认: 500 ms)
- `write_expire`: 写请求过期时间 (默认: 5000 ms)
- `writes_starved`: 写请求饥饿阈值 (默认: 2)
- `fifo_batch`: 批处理大小 (默认: 16)

---

### 4. Deadline 调度器 (Legacy)

**核心特点 (Core Features):**
- 传统单队列架构
- 为读写请求分别维护红黑树
- 按照截止时间排序
- 读请求优先于写请求
- 防止请求饿死

**工作原理 (How It Works):**
```
请求入队 → 红黑树排序 → 截止时间检查 → 批量派发
```

**优势 (Advantages):**
- ✅ 成熟稳定
- ✅ 适合机械硬盘
- ✅ 防止请求饿死
- ✅ 公平性好
- ✅ 配置简单

**劣势 (Disadvantages):**
- ❌ 单队列架构限制扩展性
- ❌ 不适合现代 NVMe 设备
- ❌ 多核环境性能受限
- ❌ 已被 MQ-Deadline 取代
- ❌ 无法充分利用多队列硬件

**适用场景 (Use Cases):**
- 传统机械硬盘 (HDD)
- 旧版内核系统
- SATA SSD (旧设备)
- 单核或低核心数系统
- 向后兼容场景

**可调参数 (Tunable Parameters):**
- `read_expire`: 读请求过期时间 (默认: 500 ms)
- `write_expire`: 写请求过期时间 (默认: 5000 ms)
- `writes_starved`: 写请求饥饿阈值 (默认: 2)
- `fifo_batch`: 批处理大小 (默认: 16)

---

## 性能特征对比 (Performance Characteristics)

| 性能指标 (Metric) | Kyber | Noop | MQ-Deadline | Deadline |
|:---|:---:|:---:|:---:|:---:|
| **随机读延迟** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **随机写延迟** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **顺序读吞吐量** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **顺序写吞吐量** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **混合工作负载** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **CPU 开销** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **多核扩展性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **公平性** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 使用建议 (Recommendations)

### 📱 移动设备 / 智能手机
**推荐**: Kyber
- 理由：优秀的延迟控制，提升用户体验
- 备选：MQ-Deadline (平衡性能)

### 💻 桌面 / 笔记本电脑
**推荐**: Kyber 或 MQ-Deadline
- SSD/NVMe: Kyber (低延迟)
- SATA SSD: MQ-Deadline (平衡)

### 🖥️ 服务器
**推荐**: MQ-Deadline
- 数据库 (OLTP): Kyber
- 文件服务器: MQ-Deadline
- Web 服务器: MQ-Deadline

### ☁️ 虚拟化环境
**推荐**: Noop (Guest OS)
- 理由：让 Host OS 处理调度更高效
- Host OS 使用: Kyber 或 MQ-Deadline

### 💾 传统硬盘 (HDD)
**推荐**: Deadline 或 MQ-Deadline
- 理由：寻道时间优化重要

---

## 如何切换调度器 (How to Change Schedulers)

### 查看当前调度器 (Check Current Scheduler)
```bash
cat /sys/block/sda/queue/scheduler
# 输出示例: [mq-deadline] kyber none
```

### 临时切换 (Temporary Change)
```bash
# 切换到 Kyber
echo kyber > /sys/block/sda/queue/scheduler

# 切换到 Noop/None (在多队列设备上显示为 "none")
echo none > /sys/block/sda/queue/scheduler

# 切换到 MQ-Deadline
echo mq-deadline > /sys/block/sda/queue/scheduler
```

**注意**: 在现代多队列 (blk-mq) 设备上，Noop 调度器显示为 "none"。两者本质相同。

### 永久切换 (Permanent Change)
在 `/etc/default/grub` 中添加内核参数：
```bash
GRUB_CMDLINE_LINUX_DEFAULT="elevator=mq-deadline"
# 或者
GRUB_CMDLINE_LINUX_DEFAULT="elevator=kyber"
```

然后更新 GRUB：
```bash
sudo update-grub  # Debian/Ubuntu
sudo grub2-mkconfig -o /boot/grub2/grub.cfg  # RHEL/CentOS
```

### Android/Magisk 模块中配置
```bash
# 在 service.sh 中添加
for block in /sys/block/*/queue/scheduler; do
    if grep -q "kyber" "$block"; then
        echo "kyber" > "$block"
    fi
done
```

---

## 性能测试命令 (Performance Testing)

### 使用 fio 测试
```bash
# 随机读测试
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread \
    --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting

# 随机写测试
fio --name=randwrite --ioengine=libaio --iodepth=16 --rw=randwrite \
    --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting

# 混合读写测试
fio --name=randrw --ioengine=libaio --iodepth=16 --rw=randrw --rwmixread=70 \
    --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting
```

---

## 调度器演进历史 (Evolution History)

```
2003 -----> Deadline (单队列)
   |
2006 -----> CFQ (完全公平队列，已废弃)
   |
2012 -----> 引入 blk-mq (多队列)
   |
2016 -----> MQ-Deadline (多队列版 Deadline)
   |
2017 -----> Kyber (专为低延迟设计)
   |
2018 -----> BFQ (预算公平队列)
   |
2021+ ----> None/Kyber 成为现代设备默认
```

---

## 总结建议表 (Summary Recommendations)

| 设备类型 | 首选调度器 | 备选调度器 | 不推荐 |
|:---|:---:|:---:|:---:|
| NVMe SSD | Kyber | MQ-Deadline | Deadline |
| SATA SSD | MQ-Deadline | Kyber | None* |
| 机械硬盘 | Deadline | MQ-Deadline | None |
| eMMC | Kyber | MQ-Deadline | - |
| UFS 3.x | Kyber | MQ-Deadline | Deadline |
| 虚拟磁盘 (Guest) | None | - | - |
| RAM 磁盘 | None | - | - |

**注**: None (Noop) 不推荐用于 SATA SSD 的生产环境，但在虚拟化 Guest OS 中可以使用。

---

## 参考资料 (References)

- Linux Kernel Documentation: Block Layer
- [Kyber I/O Scheduler](https://lwn.net/Articles/720675/)
- [Multi-Queue Block Layer](https://lwn.net/Articles/552904/)
- Android Performance Optimization Guide
- Red Hat Enterprise Linux Performance Tuning Guide

---

**最后更新 (Last Updated)**: 2025-12-25
**适用内核版本 (Kernel Version)**: Linux 4.11+
**文档版本 (Document Version)**: 1.0
