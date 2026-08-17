import asyncio
import faulthandler
import logging
import tempfile
from brain.learning.continuous_learning import ContinuousLearningPipeline

faulthandler.dump_traceback_later(20, repeat=True)
logging.basicConfig(level=logging.INFO)

def samples(n=60):
    return [{"instruction": f"اشرح مفهوم الذكاء الاصطناعي رقم {i} بالتفصيل", "output": f"الذكاء الاصطناعي رقم {i} هو فرع من علوم الحاسوب يهتم ببناء أنظمة قادرة على محاكاة الذكاء البشري وتنفيذ المهام المعقدة بكفاءة عالية.", "domain":"ai_concepts", "source_model":"gpt-4o", "quality_score":0.85} for i in range(n)]

async def main():
    with tempfile.TemporaryDirectory() as d:
        p=ContinuousLearningPipeline(storage_path=d)
        r=await asyncio.wait_for(p.run(samples()), timeout=30)
        print("RESULT", r.status, r.error, r.samples_after_dedup)
asyncio.run(main())
