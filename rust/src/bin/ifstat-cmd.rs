use ifstat_rs::net_stats::get_device_string_to_name_map;

fn main() {

    let names = get_device_string_to_name_map();
    println!("{:#?}", names);
}