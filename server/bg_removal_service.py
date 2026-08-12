"""
Background Removal Service — Uses rembg (U2Net) to remove image backgrounds.
Processes images synchronously and outputs PNG with transparent alpha channel.
"""

import io
import os

from PIL import Image
from rembg import remove


def remove_background(input_path: str, output_path: str) -> str:
    """
    Remove background from an image and save as PNG with transparency.

    Args:
        input_path: Path to the source image file.
        output_path: Path for the output PNG (must end with .png).

    Returns:
        The output_path on success.

    Raises:
        RuntimeError: If background removal fails.
    """
    try:
        with open(input_path, "rb") as f:
            input_bytes = f.read()

        output_bytes = remove(input_bytes)

        # Open result and ensure RGBA mode for transparency
        result_image = Image.open(io.BytesIO(output_bytes)).convert("RGBA")

        # Optimize: resize if excessively large (saves storage on Neon-class setups)
        max_dimension = 1024
        if max(result_image.size) > max_dimension:
            result_image.thumbnail((max_dimension, max_dimension), Image.LANCZOS)

        result_image.save(output_path, format="PNG", optimize=True)
        return output_path

    except Exception as exc:
        raise RuntimeError(f"Background removal failed: {exc}") from exc


def process_upload_with_bg_removal(original_path: str) -> str:
    """
    Convenience wrapper: takes an uploaded file path, removes background,
    saves as .png alongside, and deletes the original to save storage.

    Args:
        original_path: Path to the uploaded image.

    Returns:
        Path to the new PNG file with transparent background.
    """
    # Derive output path: same name but .png extension
    base, _ = os.path.splitext(original_path)
    output_path = f"{base}_nobg.png"

    remove_background(original_path, output_path)

    # Delete original to conserve storage
    if os.path.exists(original_path) and original_path != output_path:
        os.remove(original_path)

    return output_path
