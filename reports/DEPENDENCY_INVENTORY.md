# DEPENDENCY INVENTORY

## requirements-prod.txt
# ── Production-only dependencies ─────────────────────────────────────────────
asyncpg>=0.29.0
sqlalchemy[asyncio]>=2.0.30
alembic>=1.13.0
redis[asyncio]>=5.0.0
uvloop>=0.19.0
httptools>=0.6.0
PyJWT>=2.8.0
bcrypt>=4.1.0
prometheus-fastapi-instrumentator>=7.0.0
opentelemetry-sdk>=1.24.0
opentelemetry-instrumentation-fastapi>=0.45b0
peft>=0.11.0
trl>=0.9.0
bitsandbytes>=0.43.0

## requirements.txt
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

## pyproject.toml
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

## requirements/__init__.py

## requirements/api.txt
python-multipart>=0.0.6
aiofiles>=23.2.1
slowapi>=0.1.9

## requirements/base.txt
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
gunicorn>=21.2.0
pydantic>=2.0.0
python-dotenv>=1.0.0
structlog>=23.2.0
prometheus-client>=0.19.0
opentelemetry-api>=1.21.0
opentelemetry-sdk>=1.21.0
opentelemetry-instrumentation-fastapi>=0.42b0
httpx>=0.25.0
redis>=5.0.1
celery>=5.3.4
psycopg2-binary>=2.9.9
sqlalchemy>=2.0.23
alembic>=1.12.1
pyjwt>=2.8.0
cryptography>=41.0.5

## requirements/dev.txt
mypy>=1.7.0
ruff>=0.1.6
bandit>=1.7.5
types-redis>=4.6.0
types-requests>=2.31.0

## requirements/gpu.txt
torch>=2.1.0+cu121
torchvision>=0.16.0+cu121
torchaudio>=2.1.0+cu121
bitsandbytes>=0.41.3
transformers>=4.36.0
accelerate>=0.25.0
peft>=0.6.2
trl>=0.7.4
datasets>=2.15.0
evaluate>=0.4.1
sentencepiece>=0.1.99
safetensors>=0.4.1

## requirements/inference.txt
torch>=2.1.0
transformers>=4.36.0
accelerate>=0.25.0
sentencepiece>=0.1.99
protobuf>=4.25.0
safetensors>=0.4.1

## requirements/scheduler.txt
celery>=5.3.4
django-celery-beat>=2.5.0

## requirements/test.txt
pytest>=7.4.3
pytest-asyncio>=0.21.3
pytest-cov>=4.1.0
pytest-mock>=3.12.0
locust>=2.19.0
httpx>=0.25.0
psutil>=5.9.6
PyJWT>=2.8.0

## requirements/training.txt
torch>=2.1.0+cu121
transformers>=4.36.0
accelerate>=0.25.0
peft>=0.6.2
trl>=0.7.4
datasets>=2.15.0
evaluate>=0.4.1
deepspeed>=0.12.0
bitsandbytes>=0.41.3
wandb>=0.16.1

## requirements/worker.txt
celery>=5.3.4
kombu>=5.3.3
billiard>=4.2.0
flower>=2.0.1
