get_current_carrier() {
    local mcc_mnc_5g=$(su -mm -c "getprop gsm.operator.numeric 2>/dev/null")
    local mcc_mnc_4g_0=$(su -mm -c "getprop telephony.operator.numeric.0 2>/dev/null")
    local mcc_mnc_4g_1=$(su -mm -c "getprop telephony.operator.numeric.1 2>/dev/null")
    
    local mcc_mnc=$mcc_mnc_5g
    [ -z "$mcc_mnc" ] || [ "$mcc_mnc" = "unknown" ] && mcc_mnc=$mcc_mnc_4g_0
    [ -z "$mcc_mnc" ] || [ "$mcc_mnc" = "unknown" ] && mcc_mnc=$mcc_mnc_4g_1
    [ -z "$mcc_mnc" ] || [ "$mcc_mnc" = "unknown" ] && { echo "default"; return 0; }

    case "$mcc_mnc" in
       
        46000|46002|46007|46011|46020)
            echo "cmcc"
            ;;
        
        46003|46005|46019|46021)
            echo "ctcc"
            ;;
       
        46001|46006|46010|46016)
            echo "cucc"
            ;;
        
        *)
            echo "default"
            ;;
    esac
}