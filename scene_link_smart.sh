MODDIR="${0%/*}"
. $MODDIR/qos_priority.conf
. $MODDIR/router_mgmt_frame.conf
. $MODDIR/channel_time_slice.conf
. $MODDIR/get_current_carrier.sh

detect_game_pro() {
    local game_pkgs=(
        "com.tencent.tmgp.pubgmhd" "com.tencent.tmgp.sgame" "com.tencent.kgame"
        "com.riotgames.league.wildrift" "com.tencent.mobilelegends"
        "com.netease.na5" "com.netease.eastwood" "com.mihoyo.genshin"
        "com.mihoyo.hkrpg" "com.hypergryph.arknights"
    )
    
    for pkg in "${game_pkgs[@]}"; do
        if pidof "$pkg" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}