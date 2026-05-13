import sys
from PIL import Image

def pad_image(input_path, output_path, scale_factor=1.8):
    try:
        # Open original image
        img = Image.open(input_path)
        img = img.convert("RGBA")
        
        # Calculate new dimensions
        new_width = int(img.width * scale_factor)
        new_height = int(img.height * scale_factor)
        new_size = max(new_width, new_height)
        
        # Create a new transparent image
        new_img = Image.new("RGBA", (new_size, new_size), (0, 0, 0, 0))
        
        # Calculate position to paste the original image
        paste_x = (new_size - img.width) // 2
        paste_y = (new_size - img.height) // 2
        
        # Paste original image onto the center of the new transparent image
        new_img.paste(img, (paste_x, paste_y), img)
        
        # Save the result
        new_img.save(output_path)
        print(f"Successfully padded image and saved to {output_path}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    pad_image("assets/images/logo111.png", "assets/images/logo111_splash.png")
