import asyncio
import logging
from shared.schemas.article import Article, ArticleMetadata
from shared.utils.datetime_utils import utc_now
from data_engine.pipelines.pipeline_orchestrator import PipelineOrchestrator

logging.basicConfig(level=logging.INFO)
LONG = ("Artificial intelligence is transforming every sector of the modern economy. "
        "Machine learning algorithms detect patterns in enormous datasets at unprecedented scale. "
        "Natural language processing enables computers to read and generate human text. "
        "These breakthroughs are reshaping healthcare, finance, transportation, and education. "
        "Researchers continue to push the boundaries of what neural networks can achieve. ") * 2

def article(i):
    return Article(id=f"x{i}", title=f"Article {i}", content=LONG, url=f"https://example.com/x{i}", published_at=utc_now(), metadata=ArticleMetadata(source_id="test", language="en"))

async def main():
    articles = [article(i) for i in range(5)]
    from data_engine.processing.filtering.spam_detector import SpamDetector
    for a in articles[:1]:
        print("SPAM_DIRECT", SpamDetector().detect(a))
        print("SPAM_DETAILS", SpamDetector().detect(a).rule_details)
    orch = PipelineOrchestrator(name="diag", source_id="test", allowed_languages=["en"])
    ctx = await orch.run(articles=articles)
    print("COUNT", ctx.article_count)
    print("ERRORS", [e.to_dict() if hasattr(e, "to_dict") else str(e) for e in ctx.errors])
    print("TRACES", [t.__dict__ for t in ctx.stage_traces])
    print("META", ctx.metadata)

asyncio.run(main())
