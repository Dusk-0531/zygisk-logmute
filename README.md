# 网络优化模块 (Network Optimization Module)

## 简介 (Introduction)

这是一个专为手机流量优化设计的 Magisk 模块，提供基带满血、QoS、管理帧和信道时间片优化功能。完整稳定适配中国三大运营商（移动、联通、电信），全程静默运行。

This is a Magisk module designed for mobile data optimization, providing full baseband optimization, QoS, management frame, and channel time slice optimization. Fully compatible with China's three major carriers (CMCC, CUCC, CTCC) with silent operation.

## 功能特性 (Features)

- **基带满血优化**: 5G/4G CA (载波聚合) 优化，提升峰值速率
- **QoS 优先级**: 智能流量分类和优先级调度
- **管理帧优化**: NR/LTE 管理帧和系统信息优化
- **信道时间片**: 动态信道请求优先级调整
- **TCP 优化**: BBR 拥塞控制和快速重传
- **CPU/内存调优**: 针对网络性能的系统资源优化
- **静默备份**: 自动备份原始设置，支持一键回滚

## 安装说明 (Installation)

1. 需要已安装 Magisk v20.4 或更高版本
2. 在 Magisk Manager 中刷入本模块
3. 重启设备
4. 模块会自动检测运营商并应用相应优化

## 配置文件说明 (Configuration Files)

- `module.prop`: 模块基本信息
- `service.sh`: 主服务脚本，开机自动执行
- `modem_full.conf`: 基带优化参数
- `qos_priority.conf`: QoS 优先级配置
- `channel_time_slice.conf`: 信道时间片配置
- `router_mgmt_frame.conf`: 管理帧优化参数
- `cpu_energy_sched.conf`: CPU/内存调度配置
- `tcp_balance.conf`: TCP 协议栈优化
- `get_current_carrier.sh`: 运营商识别脚本
- `scene_link_smart.sh`: 场景感知优化
- `silent_backup_full.sh`: 备份和恢复功能
- `log_config.conf`: 日志配置

## 日志位置 (Log Location)

模块运行日志保存在: `/data/local/tmp/gt5_modem_full_opt.log`

## 注意事项 (Notes)

- 本模块专为移动网络优化设计
- 部分优化参数可能需要特定设备/内核支持
- 如遇问题可通过备份文件回滚设置
- 确保已授予 Magisk ROOT 权限

## 已修复的问题 (Fixed Issues)

1. ✅ 修复了函数调用语法错误 (core_log 函数调用)
2. ✅ 添加了缺失的 log_config.conf 配置文件
3. ✅ 修复了硬编码的模块路径，改用动态 MODDIR 变量
4. ✅ 确保模块 ID 与 module.prop 中定义的一致

## TCP 拥塞控制 (TCP Congestion Control)

模块使用 `bbr_mobile_smart` 作为默认 TCP 拥塞控制算法。如果您的内核不支持此算法，可以修改 `tcp_balance.conf` 文件，将 `TCP_CONGESTION` 改为 `bbr` 或 `cubic` 等标准算法。

## 许可证 (License)

本项目采用 Apache License 2.0 许可证。
