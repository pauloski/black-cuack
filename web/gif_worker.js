// web/gif_worker.js

// Importamos la librería gif.js (asegúrate de tener gif.js y gif.worker.js en tu carpeta web/)
importScripts('gif.js'); 

self.onmessage = function(e) {
  const { imageDatas, fps, width, height } = e.data;
  
  // Configuramos el codificador de GIF
  const gif = new GIF({
    workers: 2,
    quality: 10, // Buena calidad, buen peso
    width: width,
    height: height,
    workerScript: 'gif.worker.js' // Archivo necesario de la librería
  });

  const delay = (1000 / fps); // Retraso entre frames en ms

  // Añadimos cada imagen al GIF
  imageDatas.forEach((imageData) => {
    // Reconstruimos el ImageData a partir de los bytes recibidos
    const data = new ImageData(new Uint8ClampedArray(imageData.data), imageData.width, imageData.height);
    gif.addFrame(data, { delay: delay });
  });

  // Cuando termina de renderizar, enviamos el Blob de vuelta
  gif.on('finished', function(blob) {
    self.postMessage({ type: 'finished', blob: blob });
  });

  // Iniciamos el renderizado
  gif.render();
};