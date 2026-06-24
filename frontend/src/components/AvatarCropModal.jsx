import { useRef, useState, useEffect, useCallback } from 'react';
import { X, ZoomIn, ZoomOut, Check, Move } from 'lucide-react';
import './AvatarCropModal.css';

const CANVAS_SIZE = 320;
const CROP_RADIUS = 130;

export default function AvatarCropModal({ imageSrc, onConfirm, onClose }) {
  const canvasRef  = useRef(null);
  const imgRef     = useRef(new Image());
  const dragRef    = useRef({ active: false, startX: 0, startY: 0 });

  const [zoom, setZoom]         = useState(1);
  const [minZoom, setMinZoom]   = useState(0.5);
  const [offset, setOffset]     = useState({ x: 0, y: 0 });
  const [imgLoaded, setImgLoaded] = useState(false);
  const [isDragging, setIsDragging] = useState(false);

  useEffect(() => {
    const img = imgRef.current;
    img.onload = () => {
      const mz = Math.max(
        (CROP_RADIUS * 2) / img.naturalWidth,
        (CROP_RADIUS * 2) / img.naturalHeight
      );
      setMinZoom(mz);
      setZoom(mz);
      setOffset({ x: 0, y: 0 });
      setImgLoaded(true);
    };
    img.src = imageSrc;
  }, [imageSrc]);

  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas || !imgLoaded) return;
    const ctx = canvas.getContext('2d');
    const img = imgRef.current;

    ctx.clearRect(0, 0, CANVAS_SIZE, CANVAS_SIZE);

    const w = img.naturalWidth  * zoom;
    const h = img.naturalHeight * zoom;
    const x = CANVAS_SIZE / 2 + offset.x - w / 2;
    const y = CANVAS_SIZE / 2 + offset.y - h / 2;
    ctx.drawImage(img, x, y, w, h);

    // Darken outside
    ctx.save();
    ctx.fillStyle = 'rgba(5, 10, 25, 0.65)';
    ctx.beginPath();
    ctx.rect(0, 0, CANVAS_SIZE, CANVAS_SIZE);
    ctx.arc(CANVAS_SIZE / 2, CANVAS_SIZE / 2, CROP_RADIUS, 0, Math.PI * 2, true);
    ctx.fill('evenodd');

    // Border ring
    ctx.strokeStyle = 'rgba(255,255,255,0.5)';
    ctx.lineWidth = 2;
    ctx.setLineDash([6, 4]);
    ctx.beginPath();
    ctx.arc(CANVAS_SIZE / 2, CANVAS_SIZE / 2, CROP_RADIUS, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
  }, [imgLoaded, zoom, offset]);

  useEffect(() => { draw(); }, [draw]);

  const getPos = (e) => {
    if (e.touches) {
      return { x: e.touches[0].clientX, y: e.touches[0].clientY };
    }
    return { x: e.clientX, y: e.clientY };
  };

  const onDragStart = (e) => {
    e.preventDefault();
    const pos = getPos(e);
    dragRef.current = { active: true, startX: pos.x - offset.x, startY: pos.y - offset.y };
    setIsDragging(true);
  };

  const onDragMove = (e) => {
    if (!dragRef.current.active) return;
    const pos = getPos(e);
    setOffset({ x: pos.x - dragRef.current.startX, y: pos.y - dragRef.current.startY });
  };

  const onDragEnd = () => {
    dragRef.current.active = false;
    setIsDragging(false);
  };

  const handleConfirm = () => {
    const img  = imgRef.current;
    const size = CROP_RADIUS * 2;
    const out  = document.createElement('canvas');
    out.width  = size;
    out.height = size;
    const ctx  = out.getContext('2d');

    ctx.beginPath();
    ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
    ctx.clip();

    const w = img.naturalWidth  * zoom;
    const h = img.naturalHeight * zoom;
    const x = size / 2 + offset.x - w / 2;
    const y = size / 2 + offset.y - h / 2;
    ctx.drawImage(img, x, y, w, h);

    out.toBlob((blob) => onConfirm(blob), 'image/jpeg', 0.92);
  };

  return (
    <div className="crop-overlay" onMouseUp={onDragEnd} onTouchEnd={onDragEnd}>
      <div className="crop-modal">
        <div className="crop-header">
          <span className="crop-title">Ajuster la photo</span>
          <button className="crop-close" onClick={onClose}><X size={18} /></button>
        </div>

        <p className="crop-hint"><Move size={13} /> Faites glisser pour repositionner</p>

        <div className="crop-canvas-wrap">
          <canvas
            ref={canvasRef}
            width={CANVAS_SIZE}
            height={CANVAS_SIZE}
            className={`crop-canvas${isDragging ? ' grabbing' : ''}`}
            onMouseDown={onDragStart}
            onMouseMove={onDragMove}
            onMouseLeave={onDragEnd}
            onTouchStart={onDragStart}
            onTouchMove={onDragMove}
          />
        </div>

        <div className="crop-zoom-row">
          <button className="crop-zoom-btn" onClick={() => setZoom(z => Math.max(minZoom, z - 0.1))}>
            <ZoomOut size={16} />
          </button>
          <input
            type="range"
            min={minZoom}
            max={minZoom * 3}
            step={0.01}
            value={zoom}
            onChange={(e) => setZoom(parseFloat(e.target.value))}
            className="crop-zoom-slider"
          />
          <button className="crop-zoom-btn" onClick={() => setZoom(z => Math.min(minZoom * 3, z + 0.1))}>
            <ZoomIn size={16} />
          </button>
        </div>

        <div className="crop-footer">
          <button className="crop-btn-cancel" onClick={onClose}>Annuler</button>
          <button className="crop-btn-confirm" onClick={handleConfirm}>
            <Check size={15} /> Appliquer
          </button>
        </div>
      </div>
    </div>
  );
}
