import asyncio
import os

from openai import AsyncOpenAI


async def main() -> None:
    client = AsyncOpenAI(
        api_key=os.environ.get("GROQ_API_KEY"),
        base_url=os.environ.get("GROQ_API_BASE", "https://api.groq.com/openai/v1"),
    )
    response = await client.chat.completions.create(
        model=os.environ.get("LLM_MODEL", "openai/gpt-oss-20b"),
        messages=[{"role": "user", "content": "أجب بكلمة واحدة: اختبار"}],
        max_tokens=128,
        temperature=0.2,
        stream=False,
        reasoning_effort=os.environ.get("GROQ_REASONING_EFFORT", "low"),
    )
    choice = response.choices[0]
    message = choice.message
    print({
        "model": response.model,
        "finish_reason": choice.finish_reason,
        "content_len": len(message.content or ""),
        "has_reasoning_content": bool(getattr(message, "reasoning_content", None)),
        "reasoning_len": len(getattr(message, "reasoning_content", None) or ""),
        "usage": response.usage.model_dump() if response.usage else None,
    })


if __name__ == "__main__":
    asyncio.run(main())
