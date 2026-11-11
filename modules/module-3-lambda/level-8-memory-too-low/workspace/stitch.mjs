// Skyline Maps: tile stitcher.
// Composes a square block of 512x512 RGBA map tiles into one image buffer
// before it is handed to the encoder. The whole canvas lives in memory.
const TILE_PX = 512;
const BYTES_PER_PIXEL = 4;

export const handler = async (event) => {
  const side = event.tiles_per_side;
  const canvasPx = side * TILE_PX;
  const canvas = Buffer.alloc(canvasPx * canvasPx * BYTES_PER_PIXEL);

  // Paint every tile; touching each page of the canvas is what makes it real.
  for (let ty = 0; ty < side; ty++) {
    const tileValue = (ty % 250) + 1;
    const rowBytes = TILE_PX * BYTES_PER_PIXEL * side;
    canvas.fill(tileValue, ty * TILE_PX * rowBytes, (ty + 1) * TILE_PX * rowBytes);
  }

  return {
    canvas_px: canvasPx,
    canvas_mb: Math.round(canvas.length / (1024 * 1024)),
    checksum: canvas[0] + canvas[canvas.length - 1],
  };
};
