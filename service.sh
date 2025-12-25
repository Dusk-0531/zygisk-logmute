MODDIR=${0%/*}
. ${MODDIR}/get_current_carrier.sh
. ${MODDIR}/modem_full.conf
. ${MODDIR}/cpu_energy_sched.conf
. ${MODDIR}/tcp_balance.conf
. ${MODDIR}/qos_priority.conf
. ${MODDIR}/router_mgmt_frame.conf
. ${MODDIR}/channel_time_slice.conf
. ${MODDIR}/scene_link_smart.sh
. ${MODDIR}/silent_backup_full.sh
. ${MODDIR}/log_config.conf
core_log() {
    local log_level=$1
    local log_content=$2
    local current_time=$(date +"$LOG_TIME_FORMAT")
    
    if [ -f "$LOG_PATH" ]; then
        local log_size=$(stat -c "%s" "$LOG_PATH" 2>/dev/null)
        if [ "$log_size" -ge "$LOG_MAX_SIZE" ] || [ -z "$log_size" ]; then
            echo "" > "$LOG_PATH"
            echo "[$current_time] [info] 日志文件已清空（超过最大容量：$LOG_MAX_SIZE bytes）" >> "$LOG_PATH"
        fi
    fi
    
    echo "[$current_time] [$log_level] [核心执行] $log_content" >> "$LOG_PATH"
}

auto_get_root() {
    local retry_count=3
    local retry_interval=1
    core_log "info" "开始获取ROOT权限，最大重试次数：$retry_count"
    
    while [ "$retry_count" -gt 0 ]; do
    
        if [ "$(id -u)" -eq 0 ] && su -mm -c "echo 'root_verify' > /dev/null 2>&1"; then
            core_log "info" "ROOT权限获取成功（重试次数：$((3 - retry_count + 1))）"
            return 0
        fi
        
        core_log "warning" "ROOT权限获取失败，剩余重试次数：$((retry_count - 1))"
        sleep "$retry_interval"
        retry_count=$((retry_count - 1))
    done
    
    core_log "error" "ROOT权限获取失败（已重试3次），脚本终止运行（请确认Magisk已授权）"
    exit 1
}

auto_wait_mobile_net() {
    local max_wait=20
    local wait_count=0
    local target_ifaces=("rmnet_data0" "rmnet_data1")
    local active_iface=""
    
    core_log "info" "等待移动网络就绪，检测接口：${target_ifaces[*]}，最大等待：$max_wait秒"
    
    while [ "$wait_count" -lt "$max_wait" ]; do
        for iface in "${target_ifaces[@]}"; do
            local iface_state=$(su -mm -c "cat /sys/class/net/$iface/operstate 2>/dev/null")
            if [ "$iface_state" = "up" ]; then
                active_iface="$iface"
                break
            fi
        done
        
        if [ -n "$active_iface" ]; then
            core_log "info" "移动网络就绪，活跃接口：$active_iface（等待时长：$wait_count秒）"
            echo "$active_iface" > /data/local/tmp/gt5_active_iface.tmp
            return 0
        fi
        
        sleep 1
        wait_count=$((wait_count + 1))
    done
    core_log "warning" "网络接口未就绪（已等待$max_wait秒），脚本将继续执行"
    return 1
}