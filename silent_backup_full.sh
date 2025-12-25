MODDIR=${0%/*}
. ${MODDIR}/log_config.conf
. ${MODDIR}/modem_full.conf
. ${MODDIR}/cpu_energy_sched.conf
. ${MODDIR}/tcp_balance.conf
. ${MODDIR}/qos_priority.conf
. ${MODDIR}/router_mgmt_frame.conf
. ${MODDIR}/channel_time_slice.conf
BACKUP_PATH="/data/local/tmp/gt5_modem_full_backup.conf"
BACKUP_PARAMS=(
    "modem_5g_ca_combos:/sys/devices/platform/soc/soc:qcom,modem/5g_ca_combos"
    "modem_ca_enable:/sys/devices/platform/soc/soc:qcom,modem/ca_enable"
    "modem_perf_mode:/sys/devices/platform/soc/soc:qcom,modem/perf_mode"
    "modem_tx_power:/sys/devices/platform/soc/soc:qcom,modem/tx_power"
    "modem_5g_drx:/sys/devices/platform/soc/soc:qcom,modem/drx_cycle"
    "modem_4g_ca:/sys/devices/platform/soc/soc:qcom,modem/4g_ca_enable"
    "cpu_little_governor:/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    "cpu_little_max:/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
    "cpu_little_min:/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
    "cpu_big_governor:/sys/devices/system/cpu/cpu4/cpufreq/scaling_governor"
    "cpu_big_max:/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq"
    "cpu_big_min:/sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq"
    "mem_bandwidth:/sys/devices/platform/soc/soc:qcom,mem/bandwidth_scale"
    "mem_idle_scale:/sys/devices/platform/soc/soc:qcom,mem/idle_scale"
    "tcp_rmem:/proc/sys/net/ipv4/tcp_rmem"
    "tcp_wmem:/proc/sys/net/ipv4/tcp_wmem"
    "tcp_congestion:/proc/sys/net/ipv4/tcp_congestion_control"
    "tcp_fastopen:/proc/sys/net/ipv4/tcp_fastopen"
    "tcp_cwnd_max:/proc/sys/net/ipv4/tcp_cwnd_max"
    "qos_dscp:/sys/class/net/rmnet_data0/qos/dscp_mark"
    "qos_high_weight:/sys/class/net/rmnet_data0/queues/queue0/weight"
    "nr_sib_interval:/sys/devices/platform/soc/soc:qcom,modem/nr_sib_interval"
    "lte_mib_interval:/sys/devices/platform/soc/soc:qcom,modem/lte_mib_interval"
    "weak_signal_rsrp:/sys/devices/platform/soc/soc:qcom,modem/weak_signal_rsrp"
    "nr_channel_prio:/sys/devices/platform/soc/soc:qcom,modem/nr_channel_req_prio"
    "lte_channel_prio:/sys/devices/platform/soc/soc:qcom,modem/lte_channel_req_prio"
    "channel_sched_delay:/sys/devices/platform/soc/soc:qcom,modem/channel_sched_parse_delay"
)

backup_log() {
    local log_level=$1
    local log_content=$2
    local current_time=$(date +"$LOG_TIME_FORMAT")
    
    if [ -f "$LOG_PATH" ]; then
        local log_size=$(stat -c "%s" "$LOG_PATH" 2>/dev/null)
        if [ "$log_size" -ge "$LOG_MAX_SIZE" ] || [ -z "$log_size" ]; then
            echo "" > "$LOG_PATH"
        fi
    fi
    
    echo "[$current_time] [$log_level] [备份回滚] $log_content" >> "$LOG_PATH"
}
silent_backup_full() {
    if [ -f "$BACKUP_PATH" ]; then
        backup_log "info" "备份文件已存在（路径：$BACKUP_PATH），跳过重复备份"
        return 1
    fi

    backup_log "info" "开始执行全量核心参数备份，共${#BACKUP_PARAMS[@]}项参数"
    touch "$BACKUP_PATH"
    local backup_success_count=0
    local backup_fail_count=0
    for param in "${BACKUP_PARAMS[@]}"; do
        local param_name=$(echo "$param" | cut -d':' -f1)
        local param_path=$(echo "$param" | cut -d':' -f2)
        if [ -f "$param_path" ]; then
            local param_value=$(su -mm -c "cat '$param_path' 2>/dev/null")
            echo "$param_name=$param_value" >> "$BACKUP_PATH"
            backup_success_count=$((backup_success_count + 1))
            backup_log "debug" "参数备份成功：$param_name = $param_value（路径：$param_path）"
        else
            echo "$param_name=path_not_exist" >> "$BACKUP_PATH"
            backup_fail_count=$((backup_fail_count + 1))
            backup_log "warning" "参数备份跳过：$param_name（路径不存在：$param_path）"
        fi
    done
    if [ "$backup_success_count" -ge 1 ]; then
        backup_log "info" "全量备份完成：成功$backup_success_count项，跳过$backup_fail_count项，备份文件：$BACKUP_PATH"
        return 0
    else
        backup_log "error" "全量备份失败：无有效参数备份，删除空备份文件"
        rm -f "$BACKUP_PATH"
        return 1
    fi
}
silent_rollback_full() {
    if [ ! -f "$BACKUP_PATH" ]; then
        backup_log "error" "参数回滚失败：未找到备份文件（路径：$BACKUP_PATH）"
        return 1
    fi

    backup_log "info" "开始执行全量参数回滚，恢复至优化前状态"
    local rollback_success_count=0
    local rollback_fail_count=0
    for param in "${BACKUP_PARAMS[@]}"; do
        local param_name=$(echo "$param" | cut -d':' -f1)
        local param_path=$(echo "$param" | cut -d':' -f2)
        local param_value=$(grep "^$param_name=" "$BACKUP_PATH" | cut -d'=' -f2 2>/dev/null)
        if [ -z "$param_value" ] || [ "$param_value" = "path_not_exist" ]; then
            rollback_fail_count=$((rollback_fail_count + 1))
            backup_log "warning" "参数回滚跳过：$param_name（值无效或路径不存在）"
            continue
        fi

        if [ -f "$param_path" ]; then
            su -mm -c "echo '$param_value' > '$param_path' 2>/dev/null"
            local current_value=$(su -mm -c "cat '$param_path' 2>/dev/null")
            if echo "$current_value" | grep -q "$param_value"; then
                rollback_success_count=$((rollback_success_count + 1))
                backup_log "debug" "参数回滚成功：$param_name = $param_value（路径：$param_path）"
            else
                rollback_fail_count=$((rollback_fail_count + 1))
                backup_log "error" "参数回滚失败：$param_name（写入失败，当前值：$current_value）"
            fi
        else
            rollback_fail_count=$((rollback_fail_count + 1))
            backup_log "warning" "参数回滚跳过：$param_name（路径不存在：$param_path）"
        fi
    done

    backup_log "info" "全量回滚完成：成功$rollback_success_count项，失败/跳过$rollback_fail_count项"
    [ "$rollback_success_count" -ge 1 ] && return 0 || return 1
}
verify_backup_valid() {
    if [ -f "$BACKUP_PATH" ] && grep -q "^modem_5g_ca_combos=" "$BACKUP_PATH"; then
        backup_log "info" "备份文件有效（路径：$BACKUP_PATH）"
        return 0
    else
        backup_log "warning" "备份文件无效或不存在"
        return 1
    fi
}
force_backup_full() {
    rm -f "$BACKUP_PATH"
    backup_log "info" "触发强制备份，删除旧备份文件"
    silent_backup_full
}