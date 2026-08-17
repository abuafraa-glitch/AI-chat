import asyncio
import numpy as np
from core.embeddings import get_embedding_manager

def samples(n=60):
    return [f"اشرح مفهوم الذكاء الاصطناعي رقم {i} بالتفصيل" for i in range(n)]

async def main():
    v = np.array(await get_embedding_manager().embed_texts_to_vectors(samples()))
    v = v / np.linalg.norm(v, axis=1, keepdims=True)
    sim = v @ v.T
    off = sim[~np.eye(len(sim), dtype=bool)]
    print("min", float(off.min()), "max", float(off.max()), "mean", float(off.mean()))
    print("adjacent", [round(float(sim[i,i+1]),4) for i in range(5)])
asyncio.run(main())
