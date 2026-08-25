"""SentenceTransformer embedding model implementation."""
from __future__ import annotations

import hashlib
import logging
import math
import os
from pathlib import Path
from typing import List, Optional

from core.embeddings.base import BaseEmbeddingModel, EmbeddingConfig

logger = logging.getLogger(__name__)


class SentenceTransformerModel(BaseEmbeddingModel):
    """نموذج sentence-transformers — يدعم all-MiniLM-L6-v2 وغيره."""

    def __init__(self, config: Optional[EmbeddingConfig] = None):
        super().__init__(config or EmbeddingConfig())
        self._model = None
        self._fallback = False

    def load(self) -> None:
        """تحميل النموذج من HuggingFace (lazy)."""
        if self._loaded:
            return
        try:
            from sentence_transformers import SentenceTransformer
            configured_path = os.getenv("HAJEEN_EMBEDDING_MODEL_PATH")
            model_source = configured_path if configured_path and Path(configured_path).is_dir() else self.config.model_name
            logger.info(f"تحميل نموذج: {model_source}")
            model_kwargs = {"local_files_only": self.config.local_files_only}
            self._model = SentenceTransformer(
                model_source,
                device=self.config.device,
                cache_folder=self.config.cache_dir,
                model_kwargs=model_kwargs,
            )
            self._model.max_seq_length = self.config.max_seq_length
            # تحديث الأبعاد الفعلية من النموذج
            actual_dim = self._model.get_sentence_embedding_dimension()
            if actual_dim:
                self.config.dimensions = actual_dim
            self._loaded = True
            logger.info(f"النموذج جاهز — أبعاد: {self.config.dimensions}")
        except Exception as e:
            # لا نوقف خط RAG بسبب عدم توفر أوزان النموذج؛ نستخدم متجهات
            # حتمية محلية متوافقة الأبعاد حتى يبقى المسار قابلاً للتنفيذ.
            self._fallback = True
            self._loaded = True
            logger.warning("تعذر تحميل embedding model؛ تم تفعيل deterministic local fallback: %s", e)

    def _encode_batch(self, texts: List[str]) -> List[List[float]]:
        """ترميز دُفعة من النصوص."""
        if self._fallback:
            vectors: List[List[float]] = []
            for text in texts:
                vector = [0.0] * self.config.dimensions
                for token in text.lower().split():
                    digest = hashlib.sha256(token.encode("utf-8")).digest()
                    index = int.from_bytes(digest[:4], "big") % self.config.dimensions
                    sign = 1.0 if digest[4] % 2 else -1.0
                    vector[index] += sign
                norm = math.sqrt(sum(value * value for value in vector)) or 1.0
                vectors.append([value / norm for value in vector])
            return vectors
        if self._model is None:
            raise RuntimeError("النموذج لم يُحمَّل بعد.")
        import numpy as np
        vectors = self._model.encode(
            texts,
            batch_size=self.config.batch_size,
            normalize_embeddings=self.config.normalize_embeddings,
            show_progress_bar=self.config.show_progress,
        )
        if isinstance(vectors, np.ndarray):
            return vectors.tolist()
        return [v.tolist() for v in vectors]

    @property
    def dimensions(self) -> int:
        if self._loaded and self._model:
            dim = self._model.get_sentence_embedding_dimension()
            return dim if dim else self.config.dimensions
        return self.config.dimensions
