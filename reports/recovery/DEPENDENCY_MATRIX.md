# DEPENDENCY MATRIX

## /home/ubuntu/hajeen_recovery_workspace/source/requirements.txt
# ══════════════════════════════════════════════════════════════════════
# Hajeen Platform — Requirements
# ══════════════════════════════════════════════════════════════════════

# ── HuggingFace Ecosystem ─────────────────────────────────────────────
huggingface_hub>=0.23.0
datasets>=2.20.0
transformers>=4.41.0
tokenizers>=0.19.0
accelerate>=0.31.0
safetensors>=0.4.3
sentencepiece>=0.2.0
peft>=0.11.0

# ── Environment ──────────────────────────────────────────────────────
python-dotenv>=1.0.1

# ── Deep Learning ────────────────────────────────────────────────────
torch>=2.3.0
torchvision>=0.18.0

# ── API Framework ────────────────────────────────────────────────────
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
httpx>=0.27.0

# ── Data Processing ──────────────────────────────────────────────────
numpy>=1.26.0
pandas>=2.2.0
scipy>=1.13.0

# ── Text Processing ──────────────────────────────────────────────────
regex>=2024.5.15
langdetect>=1.0.9
beautifulsoup4>=4.12.3
lxml>=5.2.0

# ── Storage ──────────────────────────────────────────────────────────
chromadb>=0.5.0
faiss-cpu>=1.8.0
qdrant-client>=1.9.0

# ── Task Queue ───────────────────────────────────────────────────────
celery>=5.4.0
redis>=5.0.0

# ── Embeddings ───────────────────────────────────────────────────────
sentence-transformers>=3.0.0

# ── Database ─────────────────────────────────────────────────────────
sqlalchemy>=2.0.30
aiosqlite>=0.20.0

# ── Web Crawling ─────────────────────────────────────────────────────
requests>=2.32.0
urllib3>=2.2.0

# ── Monitoring & Logging ─────────────────────────────────────────────
structlog>=24.1.0
prometheus-client>=0.20.0

# ── Testing ──────────────────────────────────────────────────────────
pytest>=8.2.0
pytest-asyncio>=0.23.0

# ── YAML & Config ────────────────────────────────────────────────────
pyyaml>=6.0.1
## /home/ubuntu/hajeen_recovery_workspace/source/brain/requirements.txt
# Hajeen Brain v2 — متطلبات إضافية
# جميع المكتبات الأساسية موجودة في requirements.txt الرئيسي

# اختياري — للاستخلاص الدلالي (Semantic Memory)
# sentence-transformers>=2.2.0

# اختياري — Knowledge Graph المتقدم
# neo4j>=5.0.0
# networkx>=3.0

# اختياري — التدريب (Continuous Learning)
# peft>=0.10.0
# trl>=0.8.0
# bitsandbytes>=0.41.0

# المكتبات الأساسية المستخدمة (موجودة بالفعل في المشروع):
# fastapi
# pydantic
# httpx
# asyncio (standard library)
# pathlib (standard library)
# json (standard library)
## /home/ubuntu/hajeen_recovery_workspace/source/pyproject.toml
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'

[tool.ruff]
line-length = 88
target-version = "py311"
select = ["E", "F", "I"]
fix = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
pythonpath = ["."]
addopts = "-v"
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true
## /home/ubuntu/hajeen_recovery_workspace/current/requirements.txt
# ══════════════════════════════════════════════════════════════════════
# Hajeen Platform — Requirements
# ══════════════════════════════════════════════════════════════════════

# ── HuggingFace Ecosystem ─────────────────────────────────────────────
huggingface_hub>=0.23.0
datasets>=2.20.0
transformers>=4.41.0
tokenizers>=0.19.0
accelerate>=0.31.0
safetensors>=0.4.3
sentencepiece>=0.2.0
peft>=0.11.0

# ── Environment ──────────────────────────────────────────────────────
python-dotenv>=1.0.1

# ── Deep Learning ────────────────────────────────────────────────────
torch>=2.3.0
torchvision>=0.18.0

# ── API Framework ────────────────────────────────────────────────────
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
httpx>=0.27.0

# ── Data Processing ──────────────────────────────────────────────────
numpy>=1.26.0
pandas>=2.2.0
scipy>=1.13.0

# ── Text Processing ──────────────────────────────────────────────────
regex>=2024.5.15
langdetect>=1.0.9
beautifulsoup4>=4.12.3
lxml>=5.2.0

# ── Storage ──────────────────────────────────────────────────────────
chromadb>=0.5.0
faiss-cpu>=1.8.0
qdrant-client>=1.9.0

# ── Task Queue ───────────────────────────────────────────────────────
celery>=5.4.0
redis>=5.0.0

# ── Embeddings ───────────────────────────────────────────────────────
sentence-transformers>=3.0.0

# ── Database ─────────────────────────────────────────────────────────
sqlalchemy>=2.0.30
aiosqlite>=0.20.0

# ── Web Crawling ─────────────────────────────────────────────────────
requests>=2.32.0
urllib3>=2.2.0

# ── Monitoring & Logging ─────────────────────────────────────────────
structlog>=24.1.0
prometheus-client>=0.20.0

# ── Testing ──────────────────────────────────────────────────────────
pytest>=8.2.0
pytest-asyncio>=0.23.0

# ── YAML & Config ────────────────────────────────────────────────────
pyyaml>=6.0.1

aiobreaker>=1.2.0
feedparser>=6.0.11
tenacity>=8.2.3

## Classification
CORE: fastapi, pydantic, sqlalchemy, aiosqlite
RAG: faiss-cpu, sentence-transformers, datasketch, feedparser
DISTRIBUTED: celery, redis
TRAINING/ALIGNMENT: datasets, trl, transformers
TEST: pytest, pytest-asyncio, respx
STATUS: manifest requires reconciliation; current runtime includes prior forensic installs
