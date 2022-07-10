import sys
from PIL import Image

from matplotlib.pyplot import imread
from numpy import save


def save_bmp_to_gray():
    image_path = sys.argv[1]

    img = Image.open(image_path)

    # resize the image
    img = img.convert('L')
    # img.save("grayscale.bmp")
    # width, height = img.size

    img = img.resize((320, 200))
    # new size of image
    # print(img.size)
    img.save("result.bmp")

if __name__ == "__main__":
    save_bmp_to_gray()