use flutter_rust_bridge::frb;
use anyhow::Result;
use ifstat_rs::{net_stats as ifstat_net_stats};
use std::time::{SystemTime, UNIX_EPOCH};

#[frb]
pub struct NetDevStat {
    pub ts: u128,
    #[frb(name = "devId")]
    pub dev_id: String,
    #[frb(name = "devName")]
    pub dev_name: String,
    #[frb(name = "rxBytes")]
    pub rx_bytes: u64,
    #[frb(name = "txBytes")]
    pub tx_bytes: u64,
    #[frb(name = "statValid")]
    pub stat_valid: bool,
}



#[frb(sync)] // Synchronous mode for simplicity of the demo
pub fn get_net_dev_stats() -> Result<Vec<NetDevStat>> {

    let devices_name_map = ifstat_net_stats::get_device_string_to_name_map();
    println!("{:?}", devices_name_map);

    let mut dev_stats: Vec<NetDevStat> = Vec::new();

    let ts =  SystemTime::now()
        .duration_since(UNIX_EPOCH)?
        .as_millis();
    let rt_stats = ifstat_net_stats::get_net_dev_stats();
    match rt_stats {
        Ok(stats_map) => {
            // Convert the stats to a C string format and return the pointer
            // convert_stats_to_c(stats_map)
            println!("stats_map: {:?}", stats_map);
            stats_map.into_iter().for_each(|(dev_id, (rx_bytes, tx_bytes))| {
                let dev_name = devices_name_map.get(&dev_id);
                println!("DevName: {:?}", dev_name);
                match dev_name {
                    Some(dev_name) => {dev_stats.push(NetDevStat {
                        ts,
                        dev_id,
                        dev_name: String::from(dev_name),
                        rx_bytes, tx_bytes, stat_valid: true});}
                    None => {}
                }

            })
        }
        Err(err) => {
            // On error, return a null pointer
            // ptr::null_mut()
            println!("err: {:?}", err);
        }

    }

    // dev_stats.push(NetDevStat {
    //     dev_id: String::from("1"),
    //     rx_bytes: 1,
    //     tx_bytes: 4,
    //     stat_valid: true,
    // });
    // dev_stats.push(NetDevStat {
    //     dev_id: String::from("2"),
    //     rx_bytes: 2,
    //     tx_bytes: 8,
    //     stat_valid: true,
    // });
    // dev_stats.push(NetDevStat {
    //     dev_id: String::from("3"),
    //     rx_bytes: 3,
    //     tx_bytes: 10,
    //     stat_valid: true,
    // });

    Ok(dev_stats)
}

#[frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
