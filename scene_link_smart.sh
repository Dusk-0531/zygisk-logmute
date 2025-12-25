MODDIR=${0%/*}
. ${MODDIR}/qos_priority.conf
. ${MODDIR}/router_mgmt_frame.conf
. ${MODDIR}/channel_time_slice.conf
. ${MODDIR}/get_current_carrier.sh

detect_game_pro() {
    local game_pkgs=(
        "com.tencent.tmgp.pubgmhd" "com.tencent.tmgp.sgame" "com.tencent.kgame"
        "com.riotgames.league.wildrift" "com.tencent.mobilelegends"
        "com.netease.na5" "com.netease.eastwood"
    )
    
    for pkg in "${game_pkgs[@]}"; do
        if pidof "$pkg" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

apply_scene_optimization() {
    if detect_game_pro; then
        su -mm -c "echo $GAME_CHANNEL_RESERVE > /sys/devices/platform/soc/soc:qcom,modem/channel_reserve_enable 2>/dev/null"
        su -mm -c "echo $NR_CHANNEL_REQ_PRIO > /sys/devices/platform/soc/soc:qcom,modem/nr_channel_req_prio 2>/dev/null"
    fi
}
