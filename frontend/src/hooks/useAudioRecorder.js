import { useState, useRef, useCallback, useEffect } from 'react';

const PREFERRED_MIME = [
  'audio/webm;codecs=opus',
  'audio/webm',
  'audio/ogg;codecs=opus',
  'audio/mp4',
];

function pickMimeType() {
  if (typeof MediaRecorder === 'undefined') return null;
  return PREFERRED_MIME.find((m) => MediaRecorder.isTypeSupported(m)) ?? '';
}

export default function useAudioRecorder() {
  const [recording, setRecording] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [blob, setBlob] = useState(null);
  const [error, setError] = useState(null);

  const recorderRef = useRef(null);
  const chunksRef = useRef([]);
  const streamRef = useRef(null);
  const timerRef = useRef(null);

  const cleanup = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
    recorderRef.current = null;
    chunksRef.current = [];
  }, []);

  useEffect(() => () => cleanup(), [cleanup]);

  const start = useCallback(async () => {
    setError(null);
    setBlob(null);
    setSeconds(0);

    if (!navigator.mediaDevices?.getUserMedia) {
      setError('L\'enregistrement audio n\'est pas supporté par ce navigateur.');
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      const mimeType = pickMimeType();
      const recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      recorderRef.current = recorder;
      chunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      recorder.onstop = () => {
        const finalBlob = new Blob(chunksRef.current, {
          type: recorder.mimeType || 'audio/webm',
        });
        setBlob(finalBlob);
        cleanup();
      };

      recorder.start();
      setRecording(true);

      timerRef.current = setInterval(() => {
        setSeconds((s) => {
          // Hard cap at 5 min — auto-stop
          if (s + 1 >= 300) {
            recorder.stop();
            setRecording(false);
            return s;
          }
          return s + 1;
        });
      }, 1000);
    } catch (err) {
      setError(
        err.name === 'NotAllowedError'
          ? 'Permission micro refusée. Activez-la dans les paramètres du navigateur.'
          : 'Impossible d\'accéder au micro.'
      );
      cleanup();
    }
  }, [cleanup]);

  const stop = useCallback(() => {
    if (recorderRef.current && recorderRef.current.state !== 'inactive') {
      recorderRef.current.stop();
    }
    setRecording(false);
  }, []);

  const cancel = useCallback(() => {
    if (recorderRef.current && recorderRef.current.state !== 'inactive') {
      recorderRef.current.onstop = null;
      recorderRef.current.stop();
    }
    cleanup();
    setRecording(false);
    setBlob(null);
    setSeconds(0);
  }, [cleanup]);

  const reset = useCallback(() => {
    setBlob(null);
    setSeconds(0);
    setError(null);
  }, []);

  return { recording, seconds, blob, error, start, stop, cancel, reset };
}
