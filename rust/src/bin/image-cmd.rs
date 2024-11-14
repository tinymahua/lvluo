
use anyhow::Result;
use libheif_rs::{
    Channel, RgbChroma, ColorSpace, HeifContext,
    ItemId, LibHeif
};
fn main() -> Result<()> {
    let lib_heif = LibHeif::new();
    let ctx = HeifContext::read_from_file("X:\\tmp\\2541098333187315269.HEIC")?;
    let handle = ctx.primary_image_handle()?;
    println!("W: {:?}", handle.width());
    println!("H: {:?}", handle.height());

    let image = lib_heif.decode(
        &handle,
        ColorSpace::Rgb(RgbChroma::Rgb),
        None,
    )?;
    assert_eq!(
        image.color_space(),
        Some(ColorSpace::Rgb(RgbChroma::Rgb)),
    );
    
    Ok(())
}